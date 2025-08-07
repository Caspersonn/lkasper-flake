{ lib, pkgs, config, unstable, ... }:

let

    ## NOTE RUN aws --nrofile=web_dns s3 cp s3://docs-mcs.technative.eu-longhorn/managed_service_accounts.json ~/.aws/

    #  technative_profiles = import ./dotfiles/managed_service_accounts.nix;
    technative_profiles = "${config.home.homeDirectory}/.aws/managed_service_accounts.json";
    aws_accounts = builtins.fromJSON (lib.readFile technative_profiles);

    groups = {
        mustad_hoofcare.color = "e5a50a";
        mustad_hoofcare.shortname = "mus";
        technative.color = "9141ac";
        ddgc.color = "1c71d8";
        ddgc.ignore = false;
        improvement_it.color = "1c71d8";
        improvement_it.shortname = "iit";
        dreamlines.ignore = true;
        default.color = "cccccc";
        tracklib.ignore = false;
        pastbook.ignore = false;
        splitser.ignore = false;
        taskhero.ignoge = true;
        technative.shortname = "tn";
        innofaith.color="03a5fc";
        innofaith.shortname="inf";
        innofaith.ignore = true;
    };

    account_names = {
        GitBackup.ignore = true;
        ct_lz_audit.ignore = true;
        ct_lz_log_archive.ignore = true;
        finops.ignore = true;
        playground-student18.ignore = false;
        playground-student17.ignore = false;
        playground-student16.ignore = false;
        playground-student15.ignore = false;
        playground-student14.ignore = false;
        playground-student13.ignore = false;
        playground-student12.ignore = false;
        playground-student11.ignore = false;
        playground-student10.ignore = false;
        playground-student09.ignore = false;
        playground-student08.ignore = false;
        playground-student07.ignore = false;
        playground-student06.ignore = false;
        playground-student05.ignore = false;
        playground-student04.ignore = false;
        playground-student03.ignore = false;
        playground-student02.ignore = false;
        playground-student01.ignore = false;
        technative_workload_internal_tools_nonprod.ignore = false;
        prod.ignore = true;
        test.ignore = true;
    };

    alternative_regions = {
        "221539347604" = "us-east-2"; #mustad
        "925937276627" = "us-east-2"; #mustad
        "906347402442" = "us-west-2"; #pastbook
    };
    alternative_names = {
        #"760178553019" = "pg_wtoorren";
        "992382674167" = "iit-rrs-nonprod";
        "730335585156" = "iit-rrs-prod";
        #    "911828776050" = "minecraft";
        #    "992382674167" = "iit-nonprod";
        #    "730335585156" = "iit-prod";
    };

    normalize_group = group : __concatStringsSep "_" (builtins.filter (x: builtins.typeOf x == "string") (__split " " (lib.strings.toLower group)));

    shortname_group = account :
        let
            shortname_temp = if builtins.hasAttr groupnorm groups && builtins.hasAttr "shortname" groups.${groupnorm} then
                groups.${groupnorm}.shortname
            else
                builtins.substring 0 3 groupnorm;

            groupnorm = normalize_group account.customer_name;

        in
            lib.toUpper shortname_temp;

    # Remove spaces in profile names
    normalize_name = name: builtins.replaceStrings [" "] ["_"] name;
    account_name = account:
        normalize_name (
            if builtins.hasAttr account.account_id alternative_names
                then alternative_names."${account.account_id}"
            else account.account_name
        );

    show_account = account:
        let
            groupnorm = normalize_group account.customer_name;
            accountnorm = account_name account;
        in
            if (builtins.hasAttr groupnorm groups && builtins.hasAttr "ignore" groups.${groupnorm} && groups.${groupnorm}.ignore == true) ||
    (builtins.hasAttr accountnorm account_names && builtins.hasAttr "ignore" account_names.${accountnorm} && account_names.${accountnorm}.ignore == true)
            then false
        else true;

    tn_profile = {account_id, group } :
        let
            groupnorm = normalize_group group;
        in
            {
            inherit group;
            source_profile = "technative";
            role_arn = "arn:aws:iam::${account_id}:role/landing_zone_devops_administrator";
            region = if builtins.hasAttr account_id alternative_regions then alternative_regions."${account_id}" else "eu-central-1";
            color = if builtins.hasAttr groupnorm groups && builtins.hasAttr "color" groups.${groupnorm}
                then groups.${groupnorm}.color
            else groups.default.color;
        };
in
    {
    imports = [
        ./awscli-custom.nix
    ];

    programs.awscli_custom = {
        package = unstable.awscli2;
        enable = true;
        settings = {

            #"technative" = {
            #    aws_account_id = "technativebv";
            #    account_id = "technativebv";
            #    region = "eu-central-1";
            #    output = "table";
            #    group = "Technative";
            #};

            #"profile ActiFlow" = {
            #    role_arn = "arn:aws:iam::337810061405:role/TechnativeFullAccessRole";
            #    region = "eu-north-1";
            #    group = "ActiFlow";
            #    output = "json";
            #    source_profile = "technative";
            #};

            #"499164406685-wouter" = {
            #    region = "eu-central-1";
            #    output = "json";
            #    group = "toorren";
            #};

            #"255418484322-waardenburg" = {
            #    region = "eu-central-1";
            #    output = "json";
            #    group = "waardenburg";
            #};

            #"bedrock" = {
            #    region = "eu-central-1";
            #    output = "json";
            #    group = "bedrock";
            #};


            #"profile mustad-developer"= {
            #    role_arn = "arn:aws:iam::925937276627:role/developer";
            #    region = "us-east-2";
            #    output = "json";
            #    group = "mustad-pg";
            #    source_profile = "mustad";
            #};

            #"profile moooi"= {
            #    role_arn = "arn:aws:iam::014756588884:role/TechnativeRole";
            #    region = "eu-west-1";
            #    output = "json";
            #    group = "moooi";
            #    source_profile = "technative";
            #};

            #"profile mustad-jumphost"= {
            #    role_arn = "arn:aws:iam::925937276627:role/jumphost";
            #    region = "us-east-2";
            #    output = "json";
            #    group = "mustad-pg";
            #    source_profile = "mustad";
            #};
        }
            // builtins.listToAttrs (builtins.map (account: {
                name = "profile ${shortname_group account}-${account_name account}";
                value = tn_profile { account_id = account.account_id; group = account.customer_name; };
            }) (builtins.filter (account: show_account account) aws_accounts));

    };

}
