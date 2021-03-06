use Mojo::Base -strict;
use JSON::Validator;
use Test::Mojo;
use Test::More;

use Mojolicious::Lite;
post '/' => sub {
  my $c      = shift;
  my @errors = JSON::Validator->new->schema('data://main/spec.json')
    ->validate($c->req->json);
  $c->render(status => @errors ? 400 : 200, json => \@errors);
};

my $t = Test::Mojo->new;

$t->post_ok('/', json => {})->status_is(400)->content_like(qr{/person});
$t->post_ok('/', json => {person => {name => 'superwoman'}})->status_is(200);
$t->post_ok('/',
  json => {person => {name => 'superwoman', children => [{name => 'batboy'}]}})
  ->status_is(200);
$t->post_ok('/', json => {person => {name => 'superwoman', children => [{}]}})
  ->status_is(400)->json_is('/0/path' => '/person/children/0/name');

done_testing;

__DATA__
@@ spec.json
{
  "type": "object",
  "properties": {
    "person": {
      "$ref": "#/definitions/person"
    }
  },
  "required": [
    "person"
  ],
  "definitions": {
    "person": {
      "type": "object",
      "required": [ "name" ],
      "properties": {
        "name": {
          "type": "string"
        },
        "children": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/person"
          }
        }
      }
    }
  }
}
