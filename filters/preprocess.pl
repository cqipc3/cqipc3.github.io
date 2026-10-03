#!/usr/bin/perl
# 把 pandoc 解析不了的 Obsidian 写法转成标准写法。读 stdin,写 stdout。
#   ![[图.png]] / ![[图.png|说明]] / ![[图.png|300]]  ->  标准图片
#   ![[别的笔记]]                                   ->  [[别的笔记]](不支持内嵌笔记,降级为链接)
#   ==高亮==                                         ->  <mark>高亮</mark>
#   %%注释%%                                         ->  删除
# 文件头(YAML)、围栏代码块和行内代码里的内容保持原样。
use strict; use warnings; use utf8;
binmode(STDIN, ':utf8'); binmode(STDOUT, ':utf8');
local $/; my $text = <STDIN>;

my $head = '';
if ($text =~ s/\A(---[ \t]*\n.*?\n---[ \t]*\n)//s) { $head = $1; }

sub convert {
  my $s = shift;
  $s =~ s/%%.*?%%//gs;
  $s =~ s{!\[\[([^\]|#]+?)(?:\|([^\]]*))?\]\]}{
    my ($name, $opt) = ($1, defined $2 ? $2 : '');
    if ($name =~ /\.(?:png|jpe?g|gif|webp|svg|avif|bmp)$/i) {
      my ($alt, $attr) = ($opt, '');
      if ($opt =~ /^(\d+)(?:x(\d+))?$/) { $alt = ''; $attr = "{width=$1}"; }
      my $enc = $name; $enc =~ s/ /%20/g;
      "![$alt]($enc)$attr";
    } else { "[[$name]]"; }
  }ge;
  $s =~ s/==(?=\S)(.+?)(?<=\S)==/<mark>$1<\/mark>/g;
  return $s;
}

# 先按围栏代码块切开,再按行内代码切开,只转换普通文字
my @parts = split /(^[ \t]*(?:```|~~~).*?^[ \t]*(?:```|~~~)[ \t]*$)/ms, $text;
my $out = '';
for my $i (0 .. $#parts) {
  if ($i % 2) { $out .= $parts[$i]; next; }
  my @inl = split /(`+[^`\n]*?`+)/, $parts[$i];
  for my $j (0 .. $#inl) { $out .= ($j % 2) ? $inl[$j] : convert($inl[$j]); }
}
print $head, $out;
