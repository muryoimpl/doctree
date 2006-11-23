= module ObjectSpace 

全てのオブジェクトを操作するためのモジュール。

== Module Functions

--- _id2ref(id)

オブジェクト ID([[m:Object#__id__]])からオブジェクトを得ます。
対応するオブジェクトが存在しなければ例外 [[c:RangeError]] が発生し
ます。

--- define_finalizer(obj, proc)
--- define_finalizer(obj) {|id| ...}

obj が解放されるときに実行されるファイナライザ proc を
登録します。同じオブジェクトについて複数回呼ばれたときは置き換えで
はなく追加登録されます。

proc には、ファイナライザとして [[c:Proc]] オブジェクトを渡
します。ブロックを指定した場合は、そのブロックが proc になり
ます(しかし、後述の問題があるのでブロックでファイナライザを登録す
るのは難しいです)。

ファイナライザ proc には引数として obj の
ID([[m:Object#__id__]]) が渡されます。

以下は、define_finalizer の使い方の悪い例です。

  class Foo
    def initialize
      ObjectSpace.define_finalizer(self) {
        puts "foo"
      }
    end
  end
  Foo.new
  GC.start

これは、渡された proc の self が obj を参照しつ
づけるため。そのオブジェクトが GC の対象になりません。

[[lib:tempfile]] は、ファイナライザの使い方の
良い例になっています。これは、クラスのコンテキストで [[c:Proc]] を
生成することで上記の問題を回避しています。

  class Bar
    def Bar.callback
      proc {
        puts "bar"
      }
    end
    def initialize
      ObjectSpace.define_finalizer(self, Bar.callback)
    end
  end
  Bar.new
  GC.start

proc の呼び出しで発生した大域脱出(exitや例外)は無視されます。
これは、スクリプトのメイン処理が GC の発生によって非同期に中断され
るのを防ぐためです。不安なうちは [[unknown:Rubyの起動/-d]] オプションで
事前に例外の発生の有無を確認しておいた方が良いでしょう。

  class Baz
    def initialize
      ObjectSpace.define_finalizer self, eval %q{
        proc {
          raise "baz" rescue puts $!
          raise "baz2"
          puts "baz3"
        }
      }, TOPLEVEL_BINDING
    end
  end
  Baz.new
  GC.start
  
  # => baz

--- each_object([class_or_module]) {|object| ...}

class_or_module と [[m:Object#kind_of?]] の関係にある全ての
オブジェクトに対して繰り返します。引数が省略された時には全てのオブ
ジェクトに対して繰り返します。

ただし、次のクラスのオブジェクトについては繰り返しません:
[[c:Fixnum]],
[[c:Symbol]],
[[c:TrueClass]],
[[c:FalseClass]],
[[c:NilClass]]

とくに、class_or_module に [[c:Fixnum]] や [[c:Symbol]] などのクラスを指定した場合は、
何も繰り返さないことになります。
なお、[[c:Symbol]] については、かわりに [[m:Symbol.all_symbols]] が使用できます。
繰り返した数を返します。

--- garbage_collect

どこからもアクセスされなくなったオブジェクトを回収します。
[[m:GC#start]] と同じです。

nil を返します。

--- undefine_finalizer(obj)

obj に対するファイナライザをすべて解除します。
obj を返します。

以下は、ファイナライザの古いインタフェースです。使用すると警告メッセー
ジが出力されます。

--- add_finalizer(proc)     ((<obsolete>))

proc をファイナライザとして設定します。

[[m:ObjectSpace.call_finalizer]] で指定したオブジェクトが解放され
る時、そのオブジェクトの ID(c.f [[m:Object#__id__]])を引数に
ファイナライザが評価されます。

proc を返します。

このメソッドは、obsolete です。代わりに
[[m:ObjectSpace.define_finalizer]] を使用してください

--- call_finalizer(obj)     ((<obsolete>))

obj をファイナライザの対象オブジェクトとして設定します。
obj を返します。

このメソッドは、obsolete です。

--- finalizers      ((<obsolete>))

現在登録されているファイナライザの配列を返します。

このメソッドは、obsolete です。

--- remove_finalizer(proc)  ((<obsolete>))

指定した proc をファイナライザから取り除きます。
proc を返します。

このメソッドは、obsolete です。代わりに
[[m:ObjectSpace.undefine_finalizer]] を使用してくださ
い。
