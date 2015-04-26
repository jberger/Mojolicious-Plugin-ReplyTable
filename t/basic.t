use Mojolicious::Lite;

use Test::More;
use Test::Mojo;
use Text::CSV;
use Mojo::Collection 'c';
use Mojo::Util 'squish';

plugin 'ReplyTable';

my $data = [
  [qw/head1 head2 head3/],
  [qw/r1c1  r1c2  r1c3 /],
  [qw/r2c1  r2c2☃ r2c3 /],
];

any '/table' => sub { shift->reply->table($data) };
any '/table_header' => sub { shift->stash('reply_table.header_row' => 1)->reply->table($data) };

my $t = Test::Mojo->new;

# json

$t->get_ok('/table.json')
  ->status_is(200)
  ->content_type_like(qr'application/json')
  ->json_is($data);

# csv

$t->get_ok('/table.csv')
  ->status_is(200)
  ->content_type_like(qr'text/csv');

{
  my $csv = Text::CSV->new({binary => 1});
  my $res = $t->tx->res->body;
  open my $fh, '<', \$res;
  is_deeply $csv->getline_all($fh), $data, 'data returned as csv';
}

# html

$t->get_ok('/table.html')
  ->status_is(200)
  ->content_type_like(qr'text/html');

{
  my $res = $t->tx->res->dom->find('tbody tr')->map(sub{ $_->find('td')->map('text')->to_array })->to_array;
  is_deeply $res, $data, 'data returned as html';
}

$t->get_ok('/table_header.html')
  ->status_is(200)
  ->content_type_like(qr'text/html');

{
  my $head = $t->tx->res->dom->find('thead tr th')->map('text')->to_array;
  is_deeply $head, $data->[0], 'correct html table headers';
  my $body = $t->tx->res->dom->find('tbody tr')->map(sub{ $_->find('td')->map('text')->to_array })->to_array;
  is_deeply $body, [@$data[1..$#$data]], 'correct html table body';
}

# text

$t->get_ok('/table.txt')
  ->status_is(200)
  ->content_type_like(qr'text/plain');

{
  my $res = squish $t->tx->res->text;
  my $expect = c(@$data)->flatten->join(' ');
  is $res, $expect, 'text table has correct information';
}

# xls

{
  local %INC = %INC;
  local $INC[0] = sub{ \'die' }; # prevent load
  $t->get_ok('/table.xls')
    ->status_is(406);
}

SKIP: {
  skip 'test requires Spreadsheet::WriteExcel', 2
    unless eval { require Spreadsheet::WriteExcel; 1 };
  $t->get_ok('/table.xls')
    ->status_is(200)
    ->content_type_like(qr'application/vnd.ms-excel');
  cmp_ok $t->tx->res->body_size, '>', 0, 'has non-zero size';
}

# xlsx

{
  local %INC = %INC;
  local $INC[0] = sub{ \'die' }; # prevent load
  $t->get_ok('/table.xlsx')
    ->status_is(406);
}

SKIP: {
  skip 'test requires Excel::Writer::XLSX', 2
    unless eval { require Excel::Writer::XLSX; 1 };
  $t->get_ok('/table.xlsx')
    ->status_is(200)
    ->content_type_like(qr'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  cmp_ok $t->tx->res->body_size, '>', 0, 'has non-zero size';
}

done_testing;

