package Mojolicious::Plugin::ReplyTable;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util;

sub register {
  my ($plugin, $app, $config) = @_;
  $plugin->setup_types($app);
  push @{$app->renderer->classes}, __PACKAGE__;
  $app->helper( 'reply.table' => \&_reply_table );
}

sub _reply_table {
  my $c = shift;
  my $default = ref $_[0] ? undef : shift;
  my $data = shift || die 'table data is required';
  my %respond = (
    json => { json => $data },
    html => { template => 'reply_table', table => $data },
    csv  => sub { $_[0]->render(text => _to_csv($data)) },
    txt  => sub { $_[0]->render(text => Mojo::Util::tablify($data)) },
    xls  => sub { $_[0]->render(data => _to_xls($data)) },
    xlsx => sub { $_[0]->render(data => _to_xlsx($data)) },
    @_
  );
  if ($default) {
    $c->stash(format => $default) unless @{$c->accepts};
  }
  $c->respond_to(%respond);
}

sub _to_csv {
  my ($data) = @_;
  require Text::CSV;
  my $csv = Text::CSV->new({binary => 1});
  my $string = '';
  for my $row (@$data) {
    $csv->combine(@$row) || die $csv->error_diag;
    $string .= $csv->string . "\n";
  }
  return $string;
}

sub _to_xls {
  my ($data) = @_;
  require Spreadsheet::WriteExcel;
  open my $xfh, '>', \my $fdata or die "Failed to open filehandle: $!";
  my $workbook  = Spreahsheet::WriteExcel->new( $xfh );
  my $worksheet = $workbook->add_worksheet();
  $worksheet->write_col('A1', $data);
  $workbook->close();
  return $fdata;
};

sub _to_xlsx {
  my ($data) = @_;
  require Excel::Writer::XLSX;
  open my $xfh, '>', \my $fdata or die "Failed to open filehandle: $!";
  my $workbook  = Excel::Writer::XLSX->new( $xfh );
  my $worksheet = $workbook->add_worksheet();
  $worksheet->write_col('A1', $data);
  $workbook->close();
  return $fdata;
};

sub setup_types {
  my ($plugin, $app) = @_;
  my $types = $app->types;
  $types->type(csv => [qw{text/csv application/csv}]);
  $types->type(xls => [qw{
    application/vnd.ms-excel application/msexcel application/x-msexcel application/x-ms-excel
    application/x-excel application/x-dos_ms_excel application/xls
  }]);
  $types->type(xlsx => ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']);
}

1;

__DATA__

@@ reply_table.html.ep
% my $skip = 0;
<table>
  % if ($skip = !!stash 'reply_table.header_row') {
    <thead><tr>
      % for my $header (@{$table->[0] || []}) {
        <th><%= $header %></th>
      % }
    </tr></thead>
  % }
  <tbody>
    % for my $row (@$table) {
      % if ($skip) { $skip = 0; next }
      <tr>
        % for my $value (@$row) {
          <td><%= $value %></td>
        % }
      </tr>
    % }
  </tbody>
</table>

__END__

=head2 reply->table

  $c->reply->table([[...], [...], ... ]]);
  $c->reply->table($default => $data, html => sub { ... });

Renders an arrayref of arrayrefs (the inner arrayref being a row) in one of several formats.
The formats currently include csv, json, xls(x) (where both render as xlsx).
An optional leading argument is used as the default format when one is not otherwise requested.
Optional trailing key-value pairs are merged into the arguments to L<Mojolicious::Controller/respond_to>.

