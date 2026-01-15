{ ... }:
{
  services.kimai = {
    #enable = true;
    webserver = "nginx";

    sites."kimai.inspiravita.com" = {
      settings = {};
      database = {
        user = "root";
        name = "kimai";
        port = 3306;
        host = "localhost";
        createLocally = false;
        serverVersion = "8.4.7";
      };
    };
  };
}
