package Helper;
use strict;
use warnings;

our (@EXPORT_OK, @ISA);
use Exporter ();
@ISA = 'Exporter';
@EXPORT_OK = ( qw|
    create_tfile
    create_tfile_and_name_for_new_file_in_same_dir
    get_mode
    create_tsubdir
    get_fresh_tmp_dir
    touch_a_file_and_test
    touch_directories_and_test
    touch_left_path_and_test
    prepare_left_side_directories
| );
use File::Spec;
use File::Temp ( qw| tempdir | );
use File::Path ( qw| mkpath | );
use Path::Tiny;

sub create_tfile {
    my $tdir = shift;
    my $filename = shift || 'old';
    my $f = File::Spec->catfile($tdir, $filename);
    open my $OUT, '>', $f or die "Unable to open for writing: $!";
    binmode $OUT;
    print $OUT "\n";
    close $OUT or die "Unable to close after writing: $!";
    return $f;
}

sub create_tfile_and_name_for_new_file_in_same_dir {
    my $tdir = shift;
    my $new_filename = shift || 'new_file';
    my $old = create_tfile($tdir);
    my $new = File::Spec->catfile($tdir, $new_filename);
    return ($old, $new);
}

sub get_mode {
    my $file = shift;
    return sprintf("%04o" => ((stat($file))[2] & 07777));
}

sub create_tsubdir {
    my $tdir = shift;
    my $old = File::Spec->catdir($tdir, 'old_dir');
    my $rv = mkdir($old);
    die "Unable to create temporary subdirectory for testing: $!"
        unless $rv;
    return $old;
}

sub get_fresh_tmp_dir {
    # Adapted from FCR t/01.legacy.t
    my $tmpd = tempdir( CLEANUP => 1 );
    for my $dir ( _get_dirs($tmpd) ) {
        my @created = mkpath($dir, { mode => 0711 });
        die "Unable to create directory $dir for testing: $!" unless @created;

        path("$dir/empty")->spew("");
        path("$dir/data")->spew("oh hai\n$dir");
        path("$dir/data_tnl")->spew("oh hai\n$dir\n");
        no warnings 'once';
        if ($File::Copy::Recursive::CopyLink) {
            symlink( "data",    "$dir/symlink" );
            symlink( "noexist", "$dir/symlink-broken" );
            symlink( "..",      "$dir/symlink-loopy" );
        }
        use warnings;
    }
    return $tmpd;
}

sub _get_dirs {
    # Adapted from FCR t/01.legacy.t
    my $tempd = shift;
    my @dirs = (
        [ qw| orig | ],
        [ qw| orig foo | ],
        [ qw| orig foo bar | ],
        [ qw| orig foo baz | ],
        [ qw| orig foo bar bletch | ],
    );
    my @catdirs = ();
    for my $set (@dirs) {
        push @catdirs, File::Spec->catdir($tempd, @{$set});
    }
    return @catdirs;
}

sub touch_a_file_and_test {
    my $f = shift;
    open my $OUT, '>', $f or die "Unable to open $f for writing";
    print $OUT "\n";
    close $OUT or die "Unable to close $f after writing";
    Test::More::ok(-f $f, "Created $f for testing");
    return 1;
}

sub touch_directories_and_test {
    my ($topdir, $tdir_names) = @_;
    my @tdirs = ();
    for my $d (@{$tdir_names}) {
        my $s = File::Spec->catdir($topdir, $d);
        mkpath($s) or die "Unable to mkpath $s: $!";
        Test::More::ok(-d $s, "Directory $s created");
        push @tdirs, $s;
    }
    return @tdirs;
}

sub touch_left_path_and_test {
    my @dirs = @_;
    my $ldir = File::Spec->catdir(@dirs);
    mkpath($ldir) or die "Unable to mkpath $ldir: $!";
    Test::More::ok(-d $ldir, "Directory $ldir created");
    return $ldir;
}

sub prepare_left_side_directories {
    my ($topdir, $dirname, $subdirs) = @_;
    my $tdir = File::Spec->catdir($topdir, $dirname);
    mkpath($tdir) or die "Unable to mkpath $tdir";
    Test::More::ok(-d $tdir, "Directory $tdir created");
    my $old        = File::Spec->catdir($tdir);
    my $oldtree    = File::Spec->catdir($tdir, @{$subdirs});
    my @created = mkpath($oldtree, { mode => 0711 });
    die "Unable to create directory $oldtree for testing: $!" unless -d $oldtree;
    Test::More::ok(-d $oldtree, "Directory $oldtree created for testing");
    return ($old, $oldtree);
}

1;
