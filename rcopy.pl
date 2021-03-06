#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use File::Copy 'copy';
use File::Copy::Recursive 'rcopy';

my $iter;
my $fmt;
my $last_dir;
my $dir = '.';
my (@file, @dir, @other);


init();

sub init {
    print "f/d/q?\n>> ";
    chomp(my $init = <STDIN>);
    
    if ($init eq 'f') {
        $fmt = 'file'
    }
    elsif ($init eq 'd') {
        $fmt = 'dir'
    }
    elsif ($init eq 'q') {
        say "Exit.";
        exit;
    }
    else {
        init();
    }

    iter($fmt);
    main();
}

sub main {
    say "Put the words before & after.(or [ls/q/quit])";
    chomp(my $get = <STDIN>);
    
    unless ($get =~ /\A(q|e|quit|exit)\z/) {
        chomp $get;
        my ($before, $after);
        if ($get =~ /\A(\S+)(( +(\S+))+)/) {
            $before = $1;
            $after = $2;
            my @after = split / /, $after;
    
            my @match = ();
            my @source = ();
            my $source = '';
            my $f = sub{
                $source = shift;
                if ($source =~ /$before/) {
                push @source, "$dir/$source";
                    for (@after) {
                        next if ($_ eq '');
                        my $new = $source;
                        $new =~ s/$before/$_/;
                        if (-f $dir.'/'.$new) {
                            say "$new is already exist.";
                            next;
                        }
                        push @match, "$dir/$new";
                    }
                }
            };
            opendir (my $iter, $dir) or die;
            for $source (readdir $iter) {
                next if ($source =~ /^\./);
                if ($fmt eq 'file') {
                    if (-f $dir.'/'.$source) {
                        $f->($source);
                    }
                }
                elsif ($fmt eq 'dir') {
                    if (-d $dir.'/'.$source) {
                        $f->($source);
                    }
                }
            }
            closedir $iter;
            if (scalar(@match) > 0) {
                say "Copy it OK? [y/N]\n";
                say "from:";
                for (@source) {
                    say "\t$_";
                }
                say "to:";
                for (@match) {
                    say "\t$_";
                }
                my $source = '';
                my $c = sub {
                    $source = shift;
                    if ($source =~ /$before/) {
                        for (@after) {
                            next if ($_ eq '');
                            my $new = $source;
                            $new =~ s/$before/$_/;
                            if ($fmt eq 'file'){
                                next unless (-f $source);
                                copy($source, $new) or die $!;
                            }
                            elsif ($fmt eq 'dir'){
                                next unless (-d $source);
                                mkdir($new) unless (-d $new);
                                rcopy($source, $new) or die $!;
                            }
                        }
                    }
                };
                chomp(my $result = <STDIN>);
                if ($result =~ /\A(y|yes)\z/) {
                    opendir (my $iter, $dir) or die;
                    for $source (readdir $iter) {
                        next if ($source =~ /^\./);
                        $c->($source);
                    }
                    closedir $iter;
                } else {
                    say "Nothing changes.\n";
                }
            } else {
                say "Not matched.\n";
            }
        } else {
            say "Incorrect command.";
        }
        iter($fmt);
        init();
    } else {
        say "Exit.";
    }
}

sub iter {
    my $fmt = shift;
    (@file, @dir, @other) = '';
    opendir (my $iter, $dir) or die;
        for (readdir $iter) {
            next if ($_ =~ /\A\./);
            if (-f $dir.'/'.$_) {
                push @file, "\tfile: $_\n";
            } elsif (-d $dir.'/'.$_) {
                push @dir, "\tdir: $_\n";
                $last_dir = $_;
            } else {
                push @other, "\tother: $_\n";
            }
        }
    closedir $iter;

    say 'ls:';
    if ($fmt eq 'dir') {
        print @dir;
    }
    elsif ($fmt eq 'file') {
        print @file;
    }
    else {
        print @dir;
        print @file;
        print @other;
    }
    print "\n";
}
