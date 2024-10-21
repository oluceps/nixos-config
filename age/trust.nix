{
  hard,
  userRo,
  rootRo,
  # sdnetRo,
  # rrr,
  ...
}:
(hard [
  "general.toml"
  "dae.sub"
  "jc-do"
  "ss-az"
  "juic-san"
  "naive"
])
// (userRo [
  "atuin"
  "atuin_key"
  "ssh-cfg"
  "riro.u2f"
  "elen.u2f"
  "age"
  "pub"
  "minio"
  "prism"
  "aws-s3-cred"
  "attic"
])
// (rootRo [
  "db.key"
  "db.pem"
])
// {
  dae = {
    rekeyFile = ../sec/dae.age;
    mode = "640";
    owner = "root";
    group = "users";
    name = "d.dae";
  };
  hyst-us-cli = {
    rekeyFile = ../sec/hyst-us-cli.age;
    mode = "640";
    owner = "root";
    group = "users";
    name = "hyst-us-cli.yaml";
  };
  hyst-la-cli = {
    rekeyFile = ../sec/hyst-la-cli.age;
    mode = "640";
    owner = "root";
    group = "users";
    name = "hyst-la-cli.yaml";
  };
  hyst-hk-cli = {
    rekeyFile = ../sec/hyst-hk-cli.age;
    mode = "640";
    owner = "root";
    group = "users";
    name = "hyst-hk-cli.yaml";
  };
}
