use Test2::Bundle::Extended;
use Alien::Build::Interpolate;
use lib 'corpus/lib';

subtest 'basic usage' => sub {

  my $intr = Alien::Build::Interpolate->new;
  isa_ok $intr, 'Alien::Build::Interpolate';

  $intr->add_helper( foo => '"foo" . "foo"' );
  
  is( $intr->interpolate("bar%{foo}baz"), 'barfoofoobaz' );  
  is( $intr->interpolate("bar%%baz"), 'bar%baz' );
  
  $intr->add_helper( foo1 => sub { 'foo1' . 'foo1' } );

  is( $intr->interpolate("bar%{foo1}baz"), 'barfoo1foo1baz' );  

  $intr->add_helper( 'foomake1', undef, 'Alien::foomake' => '0.22' );
  $intr->add_helper( 'foomake2', undef, 'Alien::foomake' => '0.24' );
  $intr->add_helper( 'foomake3', undef, 'Alien::foomake' => '0.29' );
  $intr->add_helper( 'foomake4', undef, 'Alien::foobogus' => '0'   );
  
  is( $intr->interpolate("-%{foomake1}-"), '-foomake.exe-' );
  is( $intr->interpolate("-%{foomake2}-"), '-foomake.exe-' );

  eval { $intr->interpolate("-%{foomake3}-") };
  isnt( $@, '', "error!");
  note $@;

  eval { $intr->interpolate("-%{foomake4}-") };
  isnt( $@, '', "error!");
  note $@;
  
  $intr->add_helper( bar => undef, 'XYZ::ABC' => '1.234' );
  $intr->add_helper( baz => undef, 'ABC::XYZ' => '4.321' );
  
  is( [$intr->requires("%{bar}%{baz}")], [ 'XYZ::ABC' => '1.234', 'ABC::XYZ' => '4.321' ], 'requires' );

  eval { $intr->add_helper( foo1 => sub { } ) };
  like $@, qr{duplicate implementation for interpolated key foo1};

  $intr->replace_helper( foo1 => sub { 'newfoo1' } );
  is( $intr->interpolate("%{foo1}"), 'newfoo1' );

};

done_testing;