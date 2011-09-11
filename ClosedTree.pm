#!/usr/bin/perl

#
# 閉ツリー(閉路グラフ)を作成する
#

use Const;
package ClosedTree;

$DBG = 0;

sub new
{
	my $class = shift();
	my $arg = shift();

	my ( $board_x, $board_y, $initial_board_state) = split(/,/, $arg);

	if($board_x eq "" || $board_y eq "" || $initial_board_state eq "") {
		print "Not Enough Args to Construct ClosedTree. Arg= $arg";
		return;
	}
	
	my $self = 
	{
		X			=> $board_x,
		Y			=> $board_y,
		Length		=> ($board_x * $board_y),
		Initial	=> $initial_board_state,
		Board		=> $initial_board_state,
		Goal		=> make_final_board_state($initial_board_state),
		Last_Move 	=> '!',
		Tree		=> make_tree($board_x, $board_y, $initial_board_state),
		DBG			=> $DBG,
	};

	return bless $self, $class;
	
}

sub make_final_board_state($)
{
	my $initial = shift();
	my @final;

	my @allchars = split( //, '123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0');

	my $c = 0;
	for( $c = 0; $c < length($initial); $c++ )
	{
		if ( substr($initial, $c, 1) ne '=' ) {
			$final[$c] = $allchars[$c];
		} else {
			$final[$c] = '=';
		}
	}

	$final[$c - 1] = '0';
	return join('', @final);
}


sub make_tree($$$)
{
#	print "Making Tree\n";
	my ($width, $height, $board) = @_;

	#文字→数値変換テーブル作成
	my $c = 1;
	my $char_conv_table;
	foreach( split(//, '123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0') ) {
		$char_conv_table->{ $_ } = $c;
		$c++;
	}
	
	#最終形作成
	my @finish_board = split(//, make_final_board_state($board));
	
	my $length = $width * $height;
	my $tree;

	#ゼロの位置
	#$tree->{pos_zero} = index( $board, $Const::CHARZERO );
	#現在位置(=ゼロの位置)
	$tree->{pos_now} = index( $board, $Const::CHARZERO );
	#移動できない場合の値
	$tree->{-1}->{val_str} = '@';
	$tree->{-1}->{val_num} = -999;
	$tree->{-1}->{fixed}   = 1;
	
	for(my $c = 0; $c < $length; $c++)
	{
		#そのパネルの値(文字のまま)
		$tree->{$c}->{val_str} = substr($board, $c, 1);
		#そのパネルの値(数値化)
		$tree->{$c}->{val_num} = $char_conv_table->{ $tree->{$c}->{val_str} };
		#そのパネルの位置
		$tree->{$c}->{pos_me} = $c;
		#そのパネルが最終形と同じ位置にあれば固定フラグ
		$tree->{$c}->{fixed} = ($tree->{$c}->{val_str} eq $finish_board[$c]) ? 1 : 0;
		
		### ひだり！
		$tree->{$c}->{L}->{name} = "L";
		#そのパネルから左に移動できる(= 左端でない、左が移動不可パネルでない)
		if( $c - 1 >= 0 && ($c % $width != 0) && (substr($board, $c - 1, 1) ne '=') ) {
			$tree->{$c}->{L}->{position} = $c - 1;
		} else {
			$tree ->{$c}->{L}->{position} = -1;
		}
		### みぎ！
		$tree->{$c}->{R}->{name} = "R";
		#そのパネルから右に移動できる(= 右端でない、右が移動不可パネルでない)
		if ( $c + 1 < $length && ( $c % $width != $width - 1 ) && (substr($board, $c + 1, 1) ne '=') ) {
			$tree->{$c}->{R}->{position} = $c + 1;
		} else {
			$tree->{$c}->{R}->{position} = -1;
		}
		### うえ！
		$tree->{$c}->{U}->{name} = "U";
		#そのパネルから上に移動できる(= 先頭行でない、上が移動不可パネルでない)
		if ( ($c - $width > 0) && (substr($board, $c - $width, 1) ne '=') )
		{
			$tree->{$c}->{U}->{position} = $c - $width;
		} else {
			$tree->{$c}->{U}->{position} = -1;
		}
		### した！
		$tree->{$c}->{D}->{name} = "D";
		#そのパネルから下に移動できる(= 最終行でない、下が移動不可パネルでない)
		if ( ($c + $width < $length) && (substr($board, $c + $width, 1) ne '=') )
		{
			$tree->{$c}->{D}->{position} = $c + $width;
		} else {
			$tree->{$c}->{D}->{position} = -1;
		}
		
		if($DBG >= 3)
		{
			print "  node($c): pos:$tree->{$c}->{pos_me} val_str:$tree->{$c}->{val_str} val_num:$tree->{$c}->{val_num} fixed:$tree->{$c}->{fixed} ";
			print "L->$tree->{$c}->{L}->{position} / R->$tree->{$c}->{R}->{position} / U->$tree->{$c}->{U}->{position} / D->$tree->{$c}->{D}->{position}\n";
		}
	}
	
	return $tree;
}

sub select_where_to_move()
{
#	print "  Selecting where to move...\n";
	my $self = shift();
	
	my $tree = $self->{Tree};
	my $pos = $tree->{pos_now};
	my $last_move = $self->{Last_Move};
	my $max_val = $self->{Length};
	
	my $pos_l = $tree->{$pos}->{L}->{position};	#左選択肢のポジション
	my $pos_r = $tree->{$pos}->{R}->{position};	#右選択肢のポジション
	my $pos_u = $tree->{$pos}->{U}->{position};	#上選択肢のポジション
	my $pos_d = $tree->{$pos}->{D}->{position};	#下選択肢のポジション
	
	my $fix_l = $tree->{$tree->{$pos_l}->{pos_me}}->{fixed};	#定位置フラグ
	my $fix_r = $tree->{$tree->{$pos_r}->{pos_me}}->{fixed};	#定位置フラグ
	my $fix_u = $tree->{$tree->{$pos_u}->{pos_me}}->{fixed};	#定位置フラグ
	my $fix_d = $tree->{$tree->{$pos_d}->{pos_me}}->{fixed};	#定位置フラグ

	my $val_l = ($last_move !~ /R/) ? $tree->{$pos_l}->{val_num} : 0;		#スコアはとりあえずは選択肢の値
	my $val_r = ($last_move !~ /L/) ? $tree->{$pos_r}->{val_num} : 0;		#スコアはとりあえずは選択肢の値
	my $val_u = ($last_move !~ /D/) ? $tree->{$pos_u}->{val_num} : 0;		#スコアはとりあえずは選択肢の値
	my $val_d = ($last_move !~ /U/) ? $tree->{$pos_d}->{val_num} : 0;		#スコアはとりあえずは選択肢の値
	
#	$val_r = $max_val - $val_r if($val_r > 0);	#右側パネル=>最大値との差
#	$val_d = $max_val - $val_d if($val_d > 0);	#下側パネル=>最大値との差

	$val_l = ( ($val_l > 0) && ($fix_l) ) ? 0.5 : $val_l;	#定位置フラグがたってればスコアは決め打ち
	$val_r = ( ($val_r > 0) && ($fix_r) ) ? 0.5 : $val_r;	#定位置フラグがたってればスコアは決め打ち
	$val_u = ( ($val_u > 0) && ($fix_u) ) ? 0.5 : $val_u;	#定位置フラグがたってればスコアは決め打ち
	$val_d = ( ($val_d > 0) && ($fix_d) ) ? 0.5 : $val_d;	#定位置フラグがたってればスコアは決め打ち
	
	my $str_l = ($last_move !~ /R/) ? $tree->{$pos_l}->{val_str} : "*";	#左側パネルの文字
	my $str_r = ($last_move !~ /L/) ? $tree->{$pos_r}->{val_str} : "*";	#右側パネルの文字
	my $str_u = ($last_move !~ /D/) ? $tree->{$pos_u}->{val_str} : "*";	#上側パネルの文字
	my $str_d = ($last_move !~ /U/) ? $tree->{$pos_d}->{val_str} : "*";	#下側パネルの文字

	if($self->{DBG} >= 2) {
		print "    Last Move = $last_move / Pos of Now: $pos / L->p:$pos_l(v:$val_l/s:$str_l/f:$fix_l) / R->p:$pos_r(v:$val_r/s:$str_r/f:$fix_r) / U->p:$pos_u(v:$val_u/s:$str_u/f:$fix_u) / D->p:$pos_d(v:$val_d/s:$str_d/f:$fix_d)\n";
	}
	# 詰み状態
	if( $val_l <= 0 && $val_r <= 0 && $val_u <= 0 && $val_d <= 0 ) {
#		print "      !!!! This Game can't be solved !!! Sorry, We'll skip to next game...\n";
		$selected->{No_Way} = 1;
		return $selected;
	}

	#移動選択肢の中で一番大きな値を探す
	my $selected_val;
	my $selected;
	#左右比較
#	print "      1: val_l=$val_l > val_r=$val_r\n";
	if ( $val_l > $val_r ) {
		$selected_val = $val_l;		
		
		$selected = $tree->{$pos_l};
		$selected->{move_name} = 'L';
	} else {
		$selected_val = $val_r;
		$selected = $tree->{$pos_r};	
		$selected->{move_name} = 'R';
	}
	#上と比較
#	print "      2: selected=$selected_val < val_u=$val_u\n";
	if ($selected_val < $val_u) {
		$selected_val = $val_u;
		$selected = $tree->{$pos_u};
		$selected->{move_name} = 'U';
	}
	#下と比較
#	print "      3: selected=$selected_val < val_d=$val_d\n";
	if ($selected_val < $val_d) {
		$selected_val = $val_d;
		$selected = $tree->{$pos_d};
		$selected->{move_name} = 'D';
	}
	return $selected;
}

# 目標のマスを決める
sub bound_for_where()
{
	#とりあえずの戦略として左上から左下の1列
}

sub move_1step($)
{
	my $self = shift();
	my $selected = shift();
	
	my $board = $self->{Board};
	my $pos_orig = $self->{Tree}->{pos_now};	#現在位置(移動元)
	my $pos_next = $selected->{pos_me};			#移動先位置
	my $val_str_next = $selected->{val_str};	#移動先の値(文字)
	my $val_num_next = $selected->{val_num};	#移動先の値(文字)
	
#	print "  Now : pos:$pos_orig\n";
#	print "  Next: pos:$pos_next move=$selected->{move_name} str:$val_str_next num:$val_num_next\n";
	
	substr($board, $pos_orig, 1, $val_str_next);	#現在位置の値を移動先の値で置き換え
	substr($board, $pos_next, 1, $Const::CHARZERO);	#移動先の値を「0」で置き換え
	$self->{Board} = $board;
	
	# $self->{Tree} = make_tree($self->{Width}, $self->{Height}, $self->{Board});	#ツリー再作成
	
	$self->{Tree}->{pos_now} = $pos_next;					#現在位置更新
	
	$self->{Tree}->{$pos_orig}->{val_str} = $val_str_next;	#移動元の値(文字)更新
	$self->{Tree}->{$pos_orig}->{val_num} = $val_num_next;	#移動元の値(数値)更新

	$self->{Tree}->{$pos_next}->{val_str} = '0';			#移動先の値(文字)更新
	$self->{Tree}->{$pos_next}->{val_num} = '99';			#移動先の値(数値)更新
	
	$self->{Last_Move} = $selected->{move_name};			#最終動作を更新
	
	$self->renew_fixed_panel();
		
	return;
}

sub renew_fixed_panel()
{
	my $self = shift();

	my @board_now = split(//, $self->{Board});
	my @board_end = split(//, $self->{Goal});
	my $length = $self->{Length};
	
	for(my $c = 0; $c < $length; $c++)
	{
		if( $board_now[$c] eq $board_end[$c])
		{
			print "1" if($self->{DBG} >= 3);
			$self->{Tree}->{$c}->{fixed} = 1;
			
		}
		else
		{
			print "0" if($self->{DBG} >= 3);
			$self->{Tree}->{$c}->{fixed} = 0;
		}
	}
	print "\n" if($self->{DBG} >= 3);
}

1;
