{ config, lib, sloth, ... }:

let
  knownTypes = [
    "concat"
    "env"
    "instanceId"
    "mkdir"
  ];

  envOverrides = lib.filterAttrs
    (_: v: v != null)
    config.bubblewrap.env;
in
{
  _module.args.sloth = {

    type = with lib; mkOptionType {
      name = "sloth value";
      check = x:
        # string style
        (types.str.check x)
        # sloth style
        || (isAttrs x && x ? type && any (t: x.type == t) knownTypes);
    };

    instanceId = {
      type = "instanceId";
    };

    env' = key: {
      inherit key;
      type = "env";
    };

    envOr' = key: or_: {
      inherit key;
      "or" = or_;
      type = "env";
    };

    env = key:
      if (lib.hasAttr key envOverrides)
      then envOverrides.${key}
      else sloth.env' key;

    envOr = key: or_:
      if (lib.hasAttr key envOverrides)
      then envOverrides.${key}
      else sloth.envOr' key or_;

    concat = let
      isConcat = x: x.type or "" == "concat";

      backAttachable = x: isConcat x && lib.isString x.b;

      frontAttachable = x: isConcat x && lib.isString x.a;

      balanceConcats = a: b:
        if backAttachable a && lib.isString b then {
          inherit (a) a;
          b = a.b + b;
        }
        else if lib.isString a && frontAttachable b then {
          a = a + b.a;
          inherit (b) b;
        }
        else if backAttachable a && frontAttachable b then
          sloth.concat [ a.a (a.b + b.a) b.b ]
        else { inherit a b; };

      mkConcatStruct = a: b:
        if a == null then b
        else if b == null then a
        else if (lib.isString a && lib.isString b) then a + b
        else {
          type = "concat";
          inherit (balanceConcats a b) a b;
        };
    in lib.foldl' mkConcatStruct null;

    concat' = a: b: sloth.concat [ a b ];

    mkdir = dir: {
      inherit dir;
      type = "mkdir";
    };

    homeDir = sloth.env "HOME";

    homeDir' = sloth.env' "HOME";

    appDir = sloth.concat [
      sloth.homeDir'
      "/.var/app/${config.flatpak.appId}"
    ];

    appDataDir = sloth.concat' sloth.appDir "/data";

    appCacheDir = sloth.concat' sloth.appDir "/cache";

    runtimeDir = sloth.env' "XDG_RUNTIME_DIR";

    xdgCacheHome = sloth.concat' sloth.homeDir "/.cache";

    xdgConfigHome = sloth.concat' sloth.homeDir "/.config";

    xdgDataHome = sloth.concat' sloth.homeDir "/.local/share";

    xdgStateHome = sloth.concat' sloth.homeDir "/.local/state";

    uid = {
      type = "uid";
    };

    gid = {
      type = "gid";
    };

    xdgDesktopDir = sloth.concat' sloth.homeDir "/Desktop";
    xdgDocumentsDir = sloth.concat' sloth.homeDir "/Documents";
    xdgDownloadDir = sloth.concat' sloth.homeDir "/Downloads";
    xdgMusicDir = sloth.concat' sloth.homeDir "/Music";
    xdgPicturesDir = sloth.concat' sloth.homeDir "/Pictures";
    xdgPublicShareDir = sloth.concat' sloth.homeDir "/Public";
    xdgTemplatesDir = sloth.concat' sloth.homeDir "/Templates";
    xdgVideosDir = sloth.concat' sloth.homeDir "/Videos";
  };
}
