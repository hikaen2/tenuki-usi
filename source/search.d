module tenuki.search;

import std.array;
import std.algorithm.comparison;
import std.algorithm.mutation;
import std.algorithm.searching;
import std.algorithm;
import std.datetime.stopwatch;
import std.random;
import std.stdio;
import std.typecons;

import tenuki.eval, tenuki.movegen, tenuki.types, tenuki.position;


Move ponder(ref Position pos)
{
    if (pos.inMate()) {
        return Move.TORYO;
    }


    int a = short.min;
    const int b = short.max;


    Move[593] moves;
    int length = pos.legalMoves(moves);
    Tuple!(Move, int)[] movesAndScores;
    foreach (move; moves[0..length]) {
        Position p = pos.doMove(move);
        movesAndScores ~= tuple(move, -search(p, 0, -b, -a));


        //Position p = pos.doMove(move);
        //if(p.doMove(Move.NULL_MOVE).inCheck) {
        //    movesAndScores ~= tuple(move, cast(short)-10000);
        //} else {
        //    movesAndScores ~= tuple(move, -p.staticValue);
        //}
    }

    movesAndScores.sort!((a, b) => a[1] > b[1]);
    foreach (t; movesAndScores) {
        writefln("%s %s", t[0].toString(pos), t[1]);
    }

    //int bestValue = int.min;
    //
    //search0(pos, 1, outPv, bestValue);

    movesAndScores = movesAndScores.filter!(x => x[1] > -10000).array;
    //movesAndScores.randomShuffle;
    return movesAndScores[0][0];
}

///**
// * ルート局面用のsearch
// * 読み筋をstderrに出力する
// * Params:
// *      p        = 局面
// *      depth    = 探索深さ(>=1)
// *      outPv    = 読み筋を出力する
// *      outScore = 評価値を出力する
// */
//private void search0(Position pos, int depth, Move[] outPv, ref int outValue)
//{
//    Move[64] pv;
//
//    Move[593] moves;
//    int length = pos.legalMoves(moves);
//    if (length == 0) return;
//
//    randomShuffle(moves[0..length]);
//    if (outPv[0] != Move.NULL) swap(moves[0], moves[0..length].find(outPv[0])[0]);
//
//    int a = short.min;
//    const int b = short.max;
//
//    foreach (Move move; moves[0..length]) {
//        int value = -search(pos.doMove(move), depth - 1, -b, -a, pv);
//
//        if (a < value) {
//            a = value;
//            outPv[0] = move;
//            outPv[1..64] = pv[0..63];
//            outValue = value;
//        }
//    }
//    return;
//}



/**
 * search
 * @param p
 * @param depth
 * @param a 探索済みminノードの最大値
 * @param b 探索済みmaxノードの最小値
 * @return 評価値
 */
private int search(Position pos, int depth, int a, int b)
{
    assert(a < b);

    if (pos.inUchifuzume) return 10000; // 打ち歩詰めされていれば勝ち

    if (depth <= 0) return qsearch(pos, depth + 1, a, b);

    Move[593] moves;
    int length = pos.legalMoves(moves);
    if (length == 0) return pos.staticValue;

    foreach (Move move; moves[0..length]) {
        int value = -search(pos.doMove(move), depth - 1, -b, -a);
        if (a < value) {
            a = value;
            if (b <= a) return b;
        }
    }
    return a;
}


/**
 * 静止探索
 */
private int qsearch(Position pos, int depth, int a, int b)
{
    assert(a < b);

    if (depth <= 0) return pos.staticValue;

    a = max(a, pos.staticValue);
    if (b <= a) return b;

    Move[128] moves;
    int length = pos.capturelMoves(moves);
    foreach (Move move; moves[0..length]) {
        int value = -qsearch(pos.doMove(move), depth - 1, -b, -a);
        if (a < value) {
            a = value;
            if (b <= a) return b;
        }
    }
    return a;
}












///**
// * search
// * @param p
// * @param depth
// * @param a 探索済みminノードの最大値
// * @param b 探索済みmaxノードの最小値
// * @return 評価値
// */
//private int search(Position pos, int depth, int a, const int b, Move[] outPv, bool doNullMove = true)
//{
//    assert(a < b);
//
//    outPv[0] = Move.NULL;
//
//    if (pos.inUchifuzume) return 10000; // 打ち歩詰めされていれば勝ち
//
//    if (depth <= 0) return pos.staticValue;
//
//    Move[64] pv;
//    Move[593] moves;
//    int length = pos.legalMoves(moves);
//    if (length == 0) return pos.staticValue;
//
//    foreach (Move move; moves[0..length]) {
//        int value = -search(pos.doMove(move), depth - 1, -b, -a, pv);
//        if (a < value) {
//            a = value;
//            if (b <= a) return b;
//            outPv[0] = move;
//            outPv[1..64] = pv[0..63];
//        }
//    }
//    return a;
//}






//private void run()
//{
//    this.bestMoves = Move.NULL;
//    this.bestValue = int.min;
//
//    // 反復深化
//    for (int depth = 1; getMonotonicTimeMillis() < endTime; depth++) {
//        this.search0(this.pos, depth, this.bestMoves, this.bestValue);
//    }
//    return;
//}
//
///**
// * ルート局面用のsearch
// * 読み筋をstderrに出力する
// * Params:
// *      p        = 局面
// *      depth    = 探索深さ(>=1)
// *      outPv    = 読み筋を出力する
// *      outScore = 評価値を出力する
// */
//private void search0(Position pos, int depth, Move[] outPv, ref int outValue)
//{
//    Move[64] pv;
//
//    Move[593] moves;
//    int length = pos.legalMoves(moves);
//    if (length == 0) return;
//
//    randomShuffle(moves[0..length]);
//    if (outPv[0] != Move.NULL) swap(moves[0], moves[0..length].find(outPv[0])[0]);
//
//    int a = short.min;
//    const int b = short.max;
//    if (this.id == 0) {
//        stderr.writef("%d: ", depth);
//    }
//
//    foreach (Move move; moves[0..length]) {
//        int value = -this.search(pos.doMove(move), depth - 1, -b, -a, pv);
//        if (getMonotonicTimeMillis() >= endTime) return;
//
//        if (a < value) {
//            a = value;
//            outPv[0] = move;
//            outPv[1..64] = pv[0..63];
//            outValue = value;
//            this.completedDepth = depth;
//            if (this.id == 0) {
//                stderr.writef("%s(%d) ", move.toString(pos), value);
//                if (previous != move) { // 前回と違う手が見つかったら探索延長する
//                    previous = move;
//                    endTime = getMonotonicTimeMillis() + min(config.SEARCH_MILLIS, RemainingMillis - (getMonotonicTimeMillis() - startTime)); // この時間まで探索する（ミリ秒）を延長する
//                }
//            }
//        }
//    }
//    if (this.id == 0) {
//        stderr.writefln("-> %s", outPv.toString(pos));
//    }
//    return;
//}
//
///**
// * search
// * @param p
// * @param depth
// * @param a 探索済みminノードの最大値
// * @param b 探索済みmaxノードの最小値
// * @return 評価値
// */
//private int search(Position pos, int depth, int a, const int b, Move[] outPv, bool doNullMove = true)
//{
//    assert(a < b);
//
//    outPv[0] = Move.NULL;
//    if (getMonotonicTimeMillis() >= endTime) return b;
//
//    if (pos.inUchifuzume) return 15000; // 打ち歩詰めされていれば勝ち
//
//    if (depth <= 0) return this.qsearch(pos, depth + 4, a, b, outPv);
//
//    if (!pos.inCheck && depth + 1 <= 3 && b <= pos.staticValue - 300) return b;
//
//    Move[64] pv;
//
//    if (doNullMove) {
//        immutable R = 2;
//        int value = -this.search(pos.doMove(Move.NULL_MOVE), depth - R - 1, -b, -b + 1, pv, false);
//        if (b <= value) return b;
//    }
//
//    Move[593] moves;
//    int length = pos.legalMoves(moves);
//    if (length == 0) return pos.staticValue;
//
//    foreach (Move move; moves[0..length]) {
//        int value = -this.search(pos.doMove(move), depth - 1, -b, -a, pv);
//        if (a < value) {
//            a = value;
//            if (b <= a) return b;
//            outPv[0] = move;
//            outPv[1..64] = pv[0..63];
//        }
//    }
//    return a;
//}
//
///**
// * 静止探索
// */
//private int qsearch(Position pos, int depth, int a, const int b, Move[] outPv)
//{
//    assert(a < b);
//
//    outPv[0] = Move.NULL;
//    Move[64] pv;
//
//    if (depth <= 0) return pos.staticValue;
//
//    a = max(a, pos.staticValue);
//    if (b <= a) return b;
//
//    Move[128] moves;
//    int length = pos.capturelMoves(moves);
//    foreach (Move move; moves[0..length]) {
//        int value = -this.qsearch(pos.doMove(move), depth - 1, -b, -a, pv);
//        if (a < value) {
//            a = value;
//            if (b <= a) return b;
//            outPv[0] = move;
//            outPv[1..64] = pv[0..63];
//        }
//    }
//    return a;
//}
