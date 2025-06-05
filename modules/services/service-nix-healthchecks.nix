{ pkgs, ... }:
{

  healthchecks.http.twenty = {
    url = "https://twenty.tools.technative.cloud/";
  };

  environment.systemPackages = [
    pkgs.jetbrains.rust-rover
    pkgs.rustup
    pkgs.cargo-insta
    pkgs.python312Packages.playwright
    pkgs.playwright-test
    pkgs.chromium
    pkgs.cowsay
  ];

  nixpkgs.config.allowUnfree = true;

  environment.variables = {
    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.libuuid ];
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
  };


  healthchecks.localCommands.twenty_Login = pkgs.writers.writePython3 "test" { } ''
import re
from playwright.sync_api import Page, expect, sync_playwright
import time


def login(page: Page):
  page.goto("https://twenty.tools.technative.cloud/")

  # Expect a title "to contain" a substring.
  expect(page).to_have_title(re.compile("Twenty"))

  page.get_by_text("Continue with Email").click()

  page.get_by_placeholder("Email").fill("mcs-serviceaccount@technative.eu")
  page.locator('[type="submit"]').click()
  page.get_by_placeholder("Password").fill("WZ$IDY5O*xvj41")

  page.locator('[type="submit"]').click()

  time.sleep(5)


def item_with_relation(page: Page):
  page.get_by_text("People").click()
  page.get_by_text("New record").click()
  page.get_by_placeholder("F‌‌irst name").fill("Play")
  page.get_by_placeholder("L‌‌ast name").fill("Wright")
  page.get_by_text("Open").click()
  page.get_by_text("Companies").click()
  page.get_by_text("New record").click()
  page.get_by_placeholder("Name").fill("Playwright")
  page.get_by_text("Open").click()

  time.sleep(1)

  people_banner = page.get_by_role("banner").filter(has_text="People")
  people_banner.locator("button").click()
  page.get_by_placeholder("Search").fill("Play Wright")
  page.get_by_text("Play Wright", exact=True).first.click(force=True)

  page.wait_for_selector('text="Delete"', state='visible')

  page.get_by_text("Delete").dblclick(force=True)
  page.wait_for_selector('text="Delete Record"', state='visible')
  page.get_by_test_id("confirmation-modal-confirm-button").click()

  page.wait_for_selector('text="Delete Record"', state='visible')
  time.sleep(1)

  page.get_by_text("People").click()
  page.get_by_text("Play Wright").first.click(force=True)
  page.get_by_text("Open").click()

  time.sleep(1)

  page.get_by_text("Delete").click(force=True)
  page.wait_for_selector('text="Delete Record"', state='visible')
  page.get_by_test_id("confirmation-modal-confirm-button").click()


if __name__ == "__main__":
  with sync_playwright() as playwright:
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context()
    page = context.new_page()

    print("Running twenty login...")
    login(page)
    print("Login test completed successfully!")
    print("Creating data...")
    item_with_relation(page)
    print("Data creation completed successfully!")

    context.close()
    browser.close()
'';
}

