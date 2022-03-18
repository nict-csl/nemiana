# NEMIANA(Cross-Platform Execution Migration for Debugging)

## 概要

 NEMIANAは複数のプラットフォーム間でのソフトウエア解析を
支援するプラットフォームです．以下の特徴があります．

1. CPUからトレース情報を取得し，任意の時点での状態を復元します．

2. 復元された状態を，別プラットフォーム上に書き込み実行を再開する(マイ
グレーションする)ことができます．

この２つの機能により，不具合発生時点に戻った詳細な解析を可能とし，
組み込み機器等のソフトウエアのデバッグを支援します．


 NEMIANAは，大きく２つのコンポーネントで構成されています．

1. NEMIANA-CPU: プログラムを実行し，遷移情報を収集し，状態を書き込む.
   
2. NEMIANA-OS: 遷移情報から任意時点での状態を再現や，マイグレーションを実行する．


NEMIANAでは，同じISAを備えるCPU間でのマイグレーションを提供します．同
じISAに対して別の 実装形態によるNEMIANA-CPUが存在し，これらをまとめて
プラットフォームと呼びます．本リポジトリでは，RISC-V 32bit基本命令セットを対
象のISAとしたたプラットフォームに対して，以下の実装形態が提供されています．

1. QEMUによる，ソフトウエアエミューレーション実装

2. 評価ボードSiFiveによる，実機実装

3. Xilinx FPGAボードZCU104による，FPGA実装

4. VerilogシミュレータVerilatorによる，FPGAのシミュレーションによる実装

注：3と4は同一のVerilogソースにより実装されたCPUコアを利用しています．

  なお，2と3をテストするには，それぞれの(高価な)評価ボードが必要ですし，
それら評価ボードに関する知識も必要です．  NEMIANAを試しで使うには，ソ
フトウエアのみで実行やマイグレーションを実行できる，QEMUプラットフォー
ムとVerilatorプラットフォームから初めるのが良いと思います．


  現在のNEMIANA-OSは，Perlのライブラリと小規模なテストプログラムの集合
として提供されます．一般的なOSやツールのような，洗練されたフロントエン
ド(シェル，UI)はまだ提供されていません．従って，望む機能を使うには，
Perlによるコーディングが必要となります．ただし，ほとんどの機能について
は，テストプログラムが提供されているので，これらをそのまま使うか，修正
することでNEMIANAの機能を利用できると考えています．

  本書では，NEMIANAのセットアップと使い方について説明します．
NEMIANAの利用には，以下の知識が必要となります．

1. Perlプログラミングの知識

2. RISC-VのC言語及びアセンブラによるベアメタルプログラミングとGNU
Compile Collection(gcc, gdb含む)の知識

3. 各プラットフォームに対する知識

  特に，3に関しては，プラットフォームにおけるベアメタルプログラミング
ができる環境を既に利用していることが前提となります．例えば，評価ボード
SiFiveによる実機実装ではRISC-Vの組み込み向けgccとgdbを自前で用意し，
USBケーブルで接続し，JTAGデバッグする環境を用意する必要があります．ま
た，Xilinx FPGAボードZCU104によるFPGA実装を試すには，XilinxのFPGA開発
ツールを使う必要があります．NEMIANAは各プラットフォームにて既に開発・
デバッグしている技術者を支援するシステムなので，プラットフォームにおけ
る開発・デバッグ環境についてはついては詳しく解説しませんので，プラット
フォームに用意されたより詳細なドキュメントを参照してください．

NEMIANAは，Ubuntu 20.04LTS上で動作を確認しています．本ドキュメントは，
Ubuntu 20.04LTS上で実行することを前提として記述します．NEMIANA-OSを構成
するPerlライブラリとプログラムはOSに非依存に実装されているため他のOS上
でも実行できと思いますが，各プラットフォームの開発・デバッグ環境を用意
するのは難しいと思います．

## 事前準備


 NEMIANAを利用するには，以下の事前準備をする必要があります．


STEP 1. パッケージとPerlライブラリのインストール

STEP 2. ターゲットISA(RISC-V)のコンパイル環境の導入

STEP 3. ターゲットプラットフォームの実行・デバッグ環境の用意

注：NEMIANAでは，2でコンパイルした共通のバイナリを，異なるプラットフォー
ム上で実行しマイグレーションします．

  順に事前準備の手順を説明します．


### STEP 1. パッケージとPerlライブラリのインストール

実行に必要となるパッケージを，以下のコマンドでインストールします．

````
apt install build-essential
apt install libwww-perl
````

### STEP 2. ターゲットISA(RISC-V)のコンパイル環境の導入

ターゲットバイナリのコンパイルとデバッグには，GCC(GNU Compile
Collection)を用います．インターネット上では，プレビルドされたRISC-V向
けのGCCが提供されていますが，ビルド時のオプションによる様々なバリエー
ションがあります．NEMIANAで利用するISAは，RISC-V 32-bit 基本命令セット
(RV32I)のみで構成されるバイナリを出力できるGCCが必要です．特に，以下の点に注
意が必要です．

- 圧縮命令(16bit命令セット)を含まないこと．
- 浮動小数点演算命令を含まないこと．
- アトミック処理命令を含まないこと．
- 乗算，除算，剰余演算を含まないこと．

  インターネットで配布されているGCCの中には，RV32imac(32bit基本命令セッ
ト＋アトミック命令＋圧縮命令セット)のみを出力するGCCが配布されています
が，これでコンパイルされたバイナリをNEMIANAで扱うことは(現状)できませ
ん．

  ここでは，RISC-Vコミュニティの公式リポジトリからソースを取得し，コンパ
イルする場合の手順を示します．


````
apt install git autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev
git clone https://github.com/riscv/riscv-gnu-toolchain
./configure --prefix=/opt/rv32 --enable-multilib --with-arch=rv32i --with-abi=ilp32
make
````

makeには，かなり高速なマシンでも，数時間程度かかります．

makeが終わったら，正しくインストールされたかを確認するためにも，本リポジトリに含まれるサンプルプログラムを実際にコンパイルしてください．


### STEP 3. 実装形態毎の実行・デバッグ環境の用意

実装形態毎に，実行・デバッグ環境を用意します．NEMIANAでは，基本的に
baremetalで実行されるバイナリを対象としたデバッグの支援を想定しており，
NEMIANAの利用前に導入した環境にてbaremetalのバイナリをコンパイル，実行，
デバッグができることを確認してください．

ここでは，本リポジトリで対応している以下の実装形態における実行・デバッ
グ環境について，最低限の情報を解説します．

1. QEMUによる，ソフトウエアエミューレーション実装

2. VerilogシミュレータVerilatorによる，FPGAのシミュレーションによる実装

3. 評価ボードSiFiveによる，実機実装

4. Xilinx FPGAボードZCU104による，FPGA実装


評価ボードSiFive及びXilinx FPGAボードZCU104による実行には，それそれ(高
価な)対象のボードと専用の開発環境が必要となります．まずは，ソフトウェ
アだけで完結するQEMUとVerilatorにて試されることをお勧めします．


####  実装形態1. QEMUによる，ソフトウエアエミューレーション実装

QEMUのインストールは，
````
apt install qemu-system-misc
````


#### 実装形態2. VerilogシミュレータVerilatorによる，FPGAのシミュレーションによる実装

Verilatorは，以下のようにしてインストールします．
````
sudo apt install verilator
````

Verilatorは，Ubuntu20.04のデフォルトでインストールされるVerilator
4.028を使って下さい．最新の4.219ではインタフェースが変更されており，動
作しないことを確認しています.


#### 実装形態3. QEMUによる，評価ボードSiFiveによる，実機実装

#### 実装形態4. Xilinx FPGAボードZCU104による，FPGA実装

## 試しにNEMIANAを利用する


NEMIANAの利用の仕方は以下となります．

1. テスト用ターゲットソースをビルドする

2. NEMIANA-OSを実行する

3. GDBを接続し，デバッグしてみる．

4. マイグレーションし，マイグレーション先にGDBで接続する．

試しに利用するには，"sample"ディレクトリにある
サンプルプログラムを利用すると良いでしょう．

以下順に説明します．


### QEMU版の実行

````
cd sample
make qemu_gdb &
pushd ~/target/sample1
make gdb
````
でgdbが起動し，再現されたCPU状態に
gdbでアクセスすることが可能です．


### Verilator版の実行
````
cd sample
make qemu_verilator &
pushd ~/target/sample1
make gdb
````
でgdbが起動し，再現されたCPU状態に
gdbでアクセスすることが可能です．

### マイグレーションの実行

````
cd sample
make make migration1 &
pushd ~/target/sample1
make gdb
````
でgdbが起動し，マイグレーションされたCPU状態に
gdbでアクセスすることが可能です．
バグのため，stepコマンドで無限ループが発生し，
応答が返ってこなくなるので，siコマンドを
実行して下さい．

````
cd sample
make make migration2 &
pushd ~/target/sample1
make gdb
````




## Docker イメージの使い方

````
docker run -it -v /home/foo/thi_repository:/root/src neminia
````

## 評価

## ディレクトリ構成

## 著作権とライセンス

