#!/usr/bin/env bats

load test_helpers

. $(dirname $BATS_TEST_DIRNAME)/lib/commands/shim-env.sh
. $(dirname $BATS_TEST_DIRNAME)/lib/commands/reshim.sh
. $(dirname $BATS_TEST_DIRNAME)/lib/commands/install.sh

setup() {
  setup_asdf_dir
  install_dummy_plugin

  PROJECT_DIR=$HOME/project
  mkdir -p $PROJECT_DIR
  cd $PROJECT_DIR

  # asdf lib needed to run generated shims
  cp -rf $BATS_TEST_DIRNAME/../{bin,lib} $ASDF_DIR/
}

teardown() {
  clean_asdf_dir
}

@test "asdf env should execute under the environment used for a shim" {
  echo "dummy 1.0" > $PROJECT_DIR/.tool-versions
  run install_command

  run $ASDF_DIR/bin/asdf env dummy which dummy
  [ "$status" -eq 0 ]
  [ "$output" == "$ASDF_DIR/installs/dummy/1.0/bin/dummy" ]
}


@test "asdf env should execute under plugin custom environment used for a shim" {
  echo "dummy 1.0" > $PROJECT_DIR/.tool-versions
  run install_command

  echo "export FOO=bar" > $ASDF_DIR/plugins/dummy/bin/exec-env
  chmod +x $ASDF_DIR/plugins/dummy/bin/exec-env

  run $ASDF_DIR/bin/asdf env dummy
  [ "$status" -eq 0 ]
  echo $output | grep 'FOO=bar'
}

@test "asdf env should ignore plugin custom environment on system version" {
  echo "dummy 1.0" > $PROJECT_DIR/.tool-versions
  run install_command

  echo "export FOO=bar" > $ASDF_DIR/plugins/dummy/bin/exec-env
  chmod +x $ASDF_DIR/plugins/dummy/bin/exec-env

  echo "dummy system" > $PROJECT_DIR/.tool-versions

  run $ASDF_DIR/bin/asdf env dummy
  [ "$status" -eq 0 ]

  run grep 'FOO=bar' <(echo $output)
  [ "$output" == "" ]
  [ "$status" -eq 1 ]

  run $ASDF_DIR/bin/asdf env dummy which dummy
  [ "$output" == "" ]
  [ "$status" -eq 1 ]
}