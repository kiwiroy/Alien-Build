package Alien::Build::Alienfile;

use strict;
use warnings;
use Alien::Build;
use base qw( Exporter );
use Path::Tiny ();
use Carp ();

sub _path { Path::Tiny::path(@_) }

# ABSTRACT: Implementation for the alienfile spec
# VERSION

our @EXPORT = qw( requires on plugin probe configure share sys download fetch decode prefer extract patch build gather meta_prop );

sub requires
{
  my($module, $version) = @_;
  $version ||= 0;
  my $caller = caller;
  my $meta = $caller->meta;
  $meta->add_requires($meta->{phase}, $module, $version);
  ();
}

sub plugin
{
  my($name, @args) = @_;
  
  my $class;
  my $pm;
  my $found;
  
  if($name =~ /^=(.*)$/)
  {
    $class = $1;
    $pm    = $class;
    $pm =~ s!::!/!g;
    $pm .= ".pm";
    $found = 1;
  }
  
  if($name !~ /::/ && ! $found)
  {
    foreach my $inc (@INC)
    {
      # TODO: allow negotiators to work with
      # @INC hooks
      next if ref $inc;
      my $file = _path("$inc/Alien/Build/Plugin/$name/Negotiate.pm");
      if(-r $file)
      {
        $class = "Alien::Build::Plugin::${name}::Negotiate";
        $pm    = "Alien/Build/Plugin/$name/Negotiate.pm";
        $found = 1;
        last;
      }
    }
  }
  
  unless($found)
  {
    $class = "Alien::Build::Plugin::$name";
    $pm    = do {
      my $name = $name;
      $name =~ s!::!/!g;
      "Alien/Build/Plugin/$name.pm";
    };
  }
  
  unless($INC{$pm})
  {
    require $pm;
  }
  my $caller = caller;
  my $plugin = $class->new(@args);
  $plugin->init($caller->meta);
  return;
}

sub probe
{
  my($instr) = @_;
  my $caller = caller;
  if(my $phase = $caller->meta->{phase})
  {
    Carp::croak "probe must not be in a $phase block" if $phase ne 'any';
  }
  $caller->meta->register_hook(probe => $instr);
  return;
}

sub _phase
{
  my($code, $phase) = @_;
  my $caller = caller(1);
  my $meta = $caller->meta;
  local $meta->{phase} = $phase;
  $code->();
  return;
}

sub configure (&)
{
  _phase($_[0], 'configure');
}

sub sys (&)
{
  _phase($_[0], 'system');
}

sub share (&)
{
  _phase($_[0], 'share');
}

sub _in_phase
{
  my($phase) = @_;
  my $caller = caller(1);
  my(undef, undef, undef, $sub) = caller(1);
  my $meta = $caller->meta;
  $sub =~ s/^.*:://;
  Carp::croak "$sub must be in a $phase block"
    unless $meta->{phase} eq $phase;
}

sub download
{
  my($instr) = @_;
  _in_phase 'share';
  my $caller = caller;
  $caller->meta->register_hook(download => $instr);
  return;
}

sub fetch
{
  my($instr) = @_;
  _in_phase 'share';
  my $caller = caller;
  $caller->meta->register_hook(fetch => $instr);
  return;
}

sub decode
{
  my($instr) = @_;
  _in_phase 'share';
  my $caller = caller;
  $caller->meta->register_hook(decode => $instr);
  return;
}

sub prefer
{
  my($instr) = @_;
  _in_phase 'share';
  my $caller = caller;
  $caller->meta->register_hook(prefer => $instr);
  return;
}

sub extract
{
  my($instr) = @_;
  _in_phase 'share';
  my $caller = caller;
  $caller->meta->register_hook(extract => $instr);
  return;
}

sub patch
{
  my($instr) = @_;
  _in_phase 'share';
  my $caller = caller;
  $caller->meta->register_hook(patch => $instr);
  return;
}

sub build
{
  my($instr) = @_;
  _in_phase 'share';
  my $caller = caller;
  $caller->meta->register_hook(build => $instr);
  return;
}

sub gather
{
  my($instr) = @_;
  my $caller = caller;
  my $meta = $caller->meta;
  my $phase = $meta->{phase};
  Carp::croak "gather is not allowed in configure block"
    if $phase eq 'configure';
  $meta->register_hook(gather_system => $instr) if $phase =~ /^(any|system)$/;
  $meta->register_hook(gather_share => $instr)  if $phase =~ /^(any|share)$/;
  return;;
}

sub meta_prop
{
  my $caller = caller;
  my $meta = $caller->meta;
  $meta->prop;
}

sub import
{
  strict->import;
  warnings->import;
  goto &Exporter::import;
}

1;
