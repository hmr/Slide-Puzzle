#!/usr/bin/perl

use dbg;
use Const;
use ClosedTree;
use PuzzleRecorder;

use Time::HiRes qw( gettimeofday tv_interval );

$DBG = 3;
$| = 1;
$start_game = 6;
$end_game = 6;
#$start_game = 0;
#$end_game = 4999;
$max_counter = 30000;
$max_timer_sec = 9;

$start_time = "";
$end_time = "";

my @GAMES;

#データ読み込み
#print STDERR "Reading data...\n";
my $fh;
open($fh, "<resources/input.txt") || die();
my $in = <$fh>; chomp($in);
my ($lim_l, $lim_r, $lim_u, $lim_d) = split(/ /, $in);
my $in = <$fh>; chomp($in);
my $num_of_games = $in;
my $games_counter = 0;
while(<$fh>)
{
	my $in = $_;
	chomp($in);
	$GAMES[$games_counter] = $in;
	if( $games_counter % 1000 == 0) {
#		print STDERR "$games_counter";
	} elsif( $games_counter % 100 == 0) {
#		print STDERR "*";
	}
	$games_counter++;
}  
close($fh);
print "\n";
print "-----------------------------------------------------------------\n";

#ゲーム開始
for($games_counter = $start_game; $games_counter <= $end_game; $games_counter++)
{
	#ゲーム記録オブジェクト
	my $recorder = new PuzzleRecorder();
	
	#グラフ作成
	my $ct = new ClosedTree( $GAMES[$games_counter] );
	if($ct eq "")
	{
		print "Can't make ClosedTree Obj. Skip this game!\n";
		next;
	}
	$ct->{DBG} = $DBG;

	#状態を保存
	$recorder->record($ct);

	#手詰まり再開回数
	my $resume_count_over_this_game = 0;
	
	#開始時刻
	$start_time = [gettimeofday];

	#おまけ表示
	my $len = $ct->{Length};
	print "No. $games_counter\n";
	print "X=$ct->{X} / Y=$ct->{Y} / Length=$len / initial pos  ->$ct->{Tree}->{pos_now}\n";
	print "initial state->$ct->{Initial}\n";
	print "final   state->$ct->{Goal}\n";

#	for(my $c = 0; $c < $len; $c++)
#	{
#		my $tree = $ct->{Tree}->{$c};
#		#print "$c:
#		#L=$tree->{pos_L}($ct->{Tree}->{$tree->{pos_L}}->{val_str}/$ct->{Tree}->{$tree->{pos_L}}->{val_num})\
#		#R=$tree->{pos_R}($ct->{Tree}->{$tree->{pos_R}}->{val_str}/$ct->{Tree}->{$tree->{pos_R}}->{val_num})\
#		#U=$tree->{pos_U}($ct->{Tree}->{$tree->{pos_U}}->{val_str}/$ct->{Tree}->{$tree->{pos_U}}->{val_num})\
#		#D=$tree->{pos_D}($ct->{Tree}->{$tree->{pos_D}}->{val_str}/$ct->{Tree}->{$tree->{pos_D}}->{val_num})\n";
#	}
start_or_resume_game:
	#プレイ！
	solve_puzzle($ct, $recorder);
	
	#結果
	if($ct->{Solved})
	{
		print "SOLVED!\n";
		show_locus($recorder, $resume_count_over_this_game);
	}
	elsif($ct->{No_Way})
	{
		#TODO: 手詰まりの場合に一手戻るアルゴリズムを実装
		#Recorderから1手前の盤を取り出す。
		#その盤を初期値としてClosedTreeを再作成する。この際にカウンタを引き継ぐ。
		#スタックをケチるために再帰はしない。
		
		#ClosedTreeオブジェクトを再作成するのに必要な情報を収集する
		my $resume_count = $ct->{Resume_Count}	;
		my $count   = $recorder->{Count} - $resume_count - 2; #カウントは常に1進んでいるため
		my $board_x = $ct->{X};
		my $board_y = $ct->{Y};
		my $board   = $recorder->{Record}->[$count];
		my $last_move = $ct->{Last_Move};

		if($count < 0) {
			print "ERROR! count is less than 0. Skip this game\n";
			next;
		}
#		print "No_Way:  $recorder->{Count}->$count\n";
		#Recorderのカウンタを戻す
		my $recorder->{Count} = $count;
		my $game_resume = "$board_x,$board_y,$board";
		print "  No_Way: $count: $resume_count: $last_move: $game_resume\n" if($DBG >= 2);
		#1手前の盤面からClosedTreeオブジェクトを再作成する
		$ct = new ClosedTree( $game_resume );
		if($ct eq "") {
			print "Can't make renew ClosedTree OBj. Skip this game!\n";
			next;
		}
		$ct->{DBG} = $DBG;
		#$ct->{Last_Move} = $last_move;
		#再開回数＋＋
		$ct->{Resume_Count} = $resume_count + 1;
		$resume_count_over_this_game++;
#		print "  $count: $resume_count: $board\n" if($ct->{Resume_Count} % 100 == 0);
		print "  $count: $ct->{Resume_Count}: $board\n" if($DBG >= 2 && $ct->{Resume_Count} % 100 == 0);
		#ゲームやり直し
		goto start_or_resume_game;
	}
	else
	{
		my $fixed_mark = "";
		my $fixed_num  = 0;
		for(my $c = 0; $c < $ct->{Length}; $c++)
		{
			if( $ct->{Tree}->{$c}->{fixed} ) {
				$fixed_mark .= "*";
				$fixed_num++;
			} else {
				$fixed_mark .= " ";
			}
		}
		print "Give Up...(Resume: $resume_count_over_this_game / Count: $recorder->{Count} / Local count: $c / time: ",$end_time,")\n";
		print "Last State: $ct->{Board}\n";
		printf ("Fixed:%02d/%02d %s\n", $fixed_num, $ct->{Length}, $fixed_mark);
	}
}

sub solve_puzzle($$)
{
	my $ct = shift();
	my $recorder = shift();
	
	my $playing_flag = 1;
	my $c = 0;
	while($playing_flag)
	{
		if($DBG >= 1)
		{
			printf("%05d:%s\n", $c, $ct->{Board});
#			for(my $c = 0; $c < $len; $c += $ct->{X})
#			{
#				#print "      ",$c..($c + $ct->{X} - 1),"  ",substr($ct->{Board}, $c, $ct->{X}),"\n";
#				print "      ",substr($ct->{Board}, $c, $ct->{X}),"\n";
#			}
		}
		
		#次の一手を選択
		my $selecting = 1;
		my $selected;
		while($selecting) {
#			print "  Selection...\n";
			$selected = undef();
			$selected = $ct->select_where_to_move();	#一手取得
			#No Way!? 
			if( $selected->{No_Way} ) {
				$ct->{No_Way} = 1;
				return $ct;
			}
			
			#その一手が有効かどうか
			my $can_i_move_to_there = $recorder->check_move_history($selected, $ct);
			print "    move to '$selected->{move_name}'->$can_i_move_to_there\n" if($DBG >= 2);
			if( $can_i_move_to_there eq 'yes') 
			{
				#ループ抜けます
				$ct->{Resume_Count} = 0;
				$selecting = 0;
			}
			elsif ($can_i_move_to_there = 'no')
			{
				if( $selected->{move_name} eq 'L' ) {
					$ct->{Last_Move} .= 'R';
				} elsif( $selected->{move_name} eq 'R' ) {
					$ct->{Last_Move} .= 'L';
				} elsif( $selected->{move_name} eq 'U' ) {
					$ct->{Last_Move} .= 'D';
				} elsif( $selected->{move_name} eq 'D' ) {
					$ct->{Last_Move} .= 'U';
				}
#				$ct->{Last_Move} .= $selected->{move_name};	#やりなおし
#				print "    To re-select: Last_Move = $ct->{Last_Move}\n";
			}
		}
		
		#パネルを動かす
		$ct->move_1step($selected);
		#状態を保存
		$recorder->record($ct);
		$c++;
		
		#終了判定
		$end_time = sprintf("%.3g", tv_interval($start_time));
		if( $ct->{Board} eq $ct->{Goal} )
		{
			$playing_flag = 0;
			$ct->{Solved} = 1;
		} 
		#if ($c > $max_counter || (time() - $start_time > $max_timer_sec))
		if ($end_time > $max_timer_sec)
		{
#			print "count: $c / time: ",time() - $start_time,"\n";
			$playing_flag = 0;
		}
	}
	return $ct;
}

sub show_locus($$)
{
	my $recorder = shift();
	my $resume_count_over_this_game = shift();
	
	my $count = $recorder->{Count} - 1;
	
	print "Moves:";
	my $c;
	for($c = 0; $c < $count; $c++)
	{
		print $recorder->{Locus}->[$c];
	}
	print "\n";
	print "$c moves. (Resume: $resume_count_over_this_game / Count: $recorder->{Count} / Local count: $c / time: ",$end_time,")\n";
}

#my $temp_ps_header = `ps aux | head -n 1`;
#my $temp_ps_body   = `ps aux | grep perl | grep -v grep`;
#print "$temp_ps_header";
#print "$temp_ps_body";

#my $temp_history = $recorder->{History};
#my $c = 0;
#foreach(keys(%$temp_history))
#{
#	printf("%s: %04d\n", $_, $temp_history->{$_});
#	$c++;
#}
#print " ->$c moves.\n";

#my $count = $recorder->{Count};
#for( $c = 0; $c <= $count; $c++)
#{
#	#print $recorder->{Record}->[$c]->{Last_Move};
#	my $board = $recorder->{Record}->[$c];
#	print "$c:$$board->{Board}\n";
#}
#print "\n";
