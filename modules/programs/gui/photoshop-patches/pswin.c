/* pswin - hide the Photoshop windows that wine paints wrongly.
 *
 *   pswin.exe list                    list visible windows
 *   pswin.exe hide <class> [...]      hide matching windows, once
 *   pswin.exe wait <secs> <class>...  poll until every class has been hidden
 *   pswin.exe watch <class> [...]     keep hiding them until photoshop exits
 *   pswin.exe show <class> [...]      undo
 *
 * Two classes need this under wine:
 *
 *   OWL.MenuBar   wine paints it solid white through the non-client menu
 *                 paint path, hiding the File/Edit/Image labels. Hiding the
 *                 child reveals photoshop's own dark application bar
 *                 underneath, and clicks still reach it.
 *                 github.com/PhialsBasement/wine-adobe-installers issue #3
 *
 *   EmbeddedWB    photoshop's embedded IE control for the creative cloud web
 *                 view. With no adobe session it sits on "Loading..." forever,
 *                 and *closing* it takes photoshop down with it. Hiding is
 *                 safe where closing is not.
 *
 * `wait` exists because the two windows appear at different times during
 * startup: OWL.MenuBar is up long before EmbeddedWB. Exiting as soon as one
 * matched would leave the other on screen, so wait until each named class has
 * been hidden at least once (or the deadline passes).
 *
 * `watch` exists because EmbeddedWB is re-created every time photoshop opens a
 * dialog, not just once at startup. The dialog itself (class PSFloatC, e.g.
 * "New Document") is created fine and is enabled, but the new EmbeddedWB lands
 * on top of it, so the dialog looks like it never opened. A one-shot hide only
 * catches the instance present at startup; watch keeps hiding them as they
 * appear, for as long as photoshop is running.
 *
 * EnumChildWindows already walks the whole descendant tree, so this does not
 * recurse itself.
 */
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

enum { MODE_LIST, MODE_HIDE, MODE_SHOW, MODE_WAIT, MODE_WATCH };

#define MAX_CLASSES 16

static int mode = MODE_LIST;
static struct {
    const char *name;
    int hits;
} want[MAX_CLASSES];
static int nwant;

static int class_index(const char *cls)
{
    for (int i = 0; i < nwant; i++)
        if (strcmp(cls, want[i].name) == 0)
            return i;
    return -1;
}

static void visit(HWND hwnd, int top)
{
    char cls[256] = {0}, title[256] = {0};
    RECT r;

    GetClassNameA(hwnd, cls, sizeof(cls) - 1);
    GetWindowTextA(hwnd, title, sizeof(title) - 1);
    GetWindowRect(hwnd, &r);
    int w = r.right - r.left, h = r.bottom - r.top;

    if (mode == MODE_LIST) {
        if (IsWindowVisible(hwnd) && w >= 20 && h >= 10)
            printf("%s%-28s %5dx%-5d at %5d,%-5d %s%s\"%s\"\n",
                   top ? "" : "  ", cls, w, h, (int)r.left, (int)r.top,
                   IsWindowEnabled(hwnd) ? "" : "[DISABLED] ",
                   (GetWindowLongPtrA(hwnd, GWL_EXSTYLE) & WS_EX_TOPMOST)
                       ? "[topmost] " : "",
                   title);
        return;
    }

    int i = class_index(cls);
    if (i < 0)
        return;

    ShowWindow(hwnd, mode == MODE_SHOW ? SW_SHOW : SW_HIDE);
    if (!want[i].hits)
        printf("%s %-28s %dx%d at %d,%d\n",
               mode == MODE_SHOW ? "shown" : "hid  ", cls, w, h,
               (int)r.left, (int)r.top);
    want[i].hits++;
}

static BOOL CALLBACK on_child(HWND hwnd, LPARAM lp)
{
    visit(hwnd, 0);
    return TRUE;
}

static BOOL CALLBACK on_top(HWND hwnd, LPARAM lp)
{
    DWORD pid = 0;
    GetWindowThreadProcessId(hwnd, &pid);
    if (pid != (DWORD)lp)
        return TRUE;

    visit(hwnd, 1);
    EnumChildWindows(hwnd, on_child, 0);
    return TRUE;
}

static DWORD ps_pid;
static BOOL CALLBACK find_ps(HWND hwnd, LPARAM lp)
{
    char cls[256] = {0};
    GetClassNameA(hwnd, cls, sizeof(cls) - 1);
    if (strcmp(cls, "Photoshop") == 0)
        GetWindowThreadProcessId(hwnd, &ps_pid);
    return ps_pid ? FALSE : TRUE;
}

/* One enumeration pass. Returns 1 if photoshop's window was found. */
static int sweep(void)
{
    ps_pid = 0;
    EnumWindows(find_ps, 0);
    if (!ps_pid)
        return 0;
    EnumWindows(on_top, (LPARAM)ps_pid);
    return 1;
}

static int all_hit(void)
{
    for (int i = 0; i < nwant; i++)
        if (!want[i].hits)
            return 0;
    return 1;
}

int main(int argc, char **argv)
{
    int deadline = 0, argbase = 2;

    if (argc > 1 && strcmp(argv[1], "hide") == 0) mode = MODE_HIDE;
    else if (argc > 1 && strcmp(argv[1], "show") == 0) mode = MODE_SHOW;
    else if (argc > 1 && strcmp(argv[1], "wait") == 0) {
        mode = MODE_WAIT;
        if (argc < 4) {
            fprintf(stderr, "usage: pswin wait <seconds> <class> [class...]\n");
            return 2;
        }
        deadline = atoi(argv[2]);
        argbase = 3;
    }
    else if (argc > 1 && strcmp(argv[1], "watch") == 0) mode = MODE_WATCH;

    if (mode != MODE_LIST) {
        for (int i = argbase; i < argc && nwant < MAX_CLASSES; i++)
            want[nwant++].name = argv[i];
        if (!nwant) {
            fprintf(stderr, "usage: pswin {hide|show|watch} <class> [class...]\n");
            return 2;
        }
    }

    if (mode == MODE_HIDE || mode == MODE_SHOW || mode == MODE_LIST) {
        if (!sweep()) {
            fprintf(stderr, "photoshop is not running\n");
            return 1;
        }
        return (mode == MODE_LIST || all_hit()) ? 0 : 1;
    }

    if (mode == MODE_WAIT) {
        /* Hide each window as it shows up, until all are done. The effective
         * mode is hide; MODE_WAIT only changes the loop, not visit(). */
        mode = MODE_HIDE;
        for (int elapsed = 0; elapsed < deadline; elapsed++) {
            sweep();
            if (all_hit())
                return 0;
            Sleep(1000);
        }

        for (int i = 0; i < nwant; i++)
            if (!want[i].hits)
                fprintf(stderr, "timed out waiting for %s\n", want[i].name);
        return 1;
    }

    /* MODE_WATCH: hide on sight, forever. Photoshop re-creates EmbeddedWB for
     * every dialog it opens, so this has to outlive startup. Give it two
     * minutes to appear at all, then follow photoshop's lifetime: once its
     * window has been seen, a later sweep finding nothing means it exited. */
    mode = MODE_HIDE;
    int seen_photoshop = 0;
    for (int idle = 0; ; ) {
        if (sweep()) {
            seen_photoshop = 1;
            idle = 0;
        } else if (seen_photoshop || ++idle > 120) {
            return 0;
        }
        Sleep(1000);
    }
}
