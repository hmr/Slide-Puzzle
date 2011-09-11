#!/usr/bin/perl

use Const;
package  PuzzleRecorder;

sub new
{
	my $class = shift();

	my $self = 
	{
		Count	=> 0,
		History	=> {},
		Record	=> [],
	};

	return bless $self, $class;
}

sub record($)
{
	my $self = shift();
	my $ct_object = shift();

	my $count = $self->{Count};

	#ハッシュ更新
	$self->{History}->{ $ct_object->{Board} } += 1;

	#盤履歴追加
	$self->{Record}->[$count] = $ct_object->{Board};
	
	#移動履歴追加
	$self->{Locus}->[$count] = $ct_object->{Last_Move};

	#$self->{Record}->[$count] = \$ct_object; #履歴オブジェクト追加
	#push( @$self{Record}, $ct_object ); #履歴オブジェクト追加

	$count++;
	$self->{Count} = $count; #カウントアップ
}

sub check_move_history($selected, $ct)
{
	my $self = shift();		#当オブジェクト
	my $selected = shift();	#選択された手
	my $ct_obj = shift();	#ClosedTreeオブジェクト
	
	#試しに手を進めてみる
	my $board = $ct_obj->{Board};
	my $pos_orig = $ct_obj->{Tree}->{pos_now};	#現在位置(移動元)
	my $pos_next = $selected->{pos_me};			#移動先位置
	my $val_str_next = $selected->{val_str};	#移動先の値(文字)
	my $val_num_next = $selected->{val_num};	#移動先の値(文字)
	
	substr($board, $pos_orig, 1, $val_str_next);	#現在位置の値を移動先の値で置き換え
	substr($board, $pos_next, 1, $Const::CHARZERO);	#移動先の値を「0」で置き換え
	
	#手を進めた状態の盤が既にHistoryにあれば却下
#	print "  Attempting new step... ";
	if ( defined($self->{History}->{$board}) ) {
#		print "NO!\n";
		return 'no';
	} else {
#		print "OK\n";
		return 'yes';
	}
}

1;
