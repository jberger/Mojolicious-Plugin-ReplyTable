#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name        => 'Mojolicious::Plugin::ReplyTable',
  dist_author        => 'Joel Berger <joel.a.berger@gmail.com>',
  license            => 'perl',
  configure_requires => { 'Module::Build' => 0.38 },
  requires => {
    'Mojolicious'  => '5.00',
    'Text::CSV' => 0,
  },
  recommends => {
    'Spreadsheet::WriteExcel' => 0,
    'Excel::Writer::XLSX' => 0,
  },
  meta_merge => {
    resources => {
      repository => 'https://github.com/jberger/Mojolicious-Plugin-ReplyTable',
      bugtracker => 'https://github.com/jberger/Mojolicious-Plugin-ReplyTable/issues',
    },
  },
);

$build->create_build_script;
