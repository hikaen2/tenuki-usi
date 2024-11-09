module tenuki.movegen;

import std.stdint;
import tenuki.types, tenuki.position;


/**
 * まだ指していない指し手mが局面pにおいて王手をかける手かどうかを返す
 */
// bool isCheck(Move m, const ref Position p)
// {
//     Square sq = (p.sideToMove << 4) | (m.isDrop ? m.from : m.isPromote ? p.board[m.from].promote : p.board[m.from]);
//     foreach (Dir d; DIRECTIONS[sq]) {
//         for (int to = m.to + d.value; !isOverBound(to - d.value, to) && (p.board[to] == Square.EMPTY || p.board[to].isEnemyOf(p.sideToMove));  to += d.value) {
//             if (p.board[to].type == Type.KING) {
//                 return true;
//             }
//             if (!d.isFly) {
//                 break;
//             }
//         }
//     }
//     return false;
// }


/**
 * 局面pにおいて手番のある側が打ち歩詰めされているかどうかを返す
 */
bool inUchifuzume(Position p)
{
    if (!p.previousMove.isDrop || p.previousMove.type != Type.PAWN || !p.inCheck) {
        return false; // 直前の指し手が打ち歩でない，または現局面が王手をかけられていない場合は，打ち歩詰めでない
    }

    Move[593] moves;
    int length = p.legalMoves(moves);
    foreach (Move move; moves[0..length]) {
        if (!p.doMove(move).doMove(Move.NULL_MOVE).inCheck) {
            return false; // 王手を解除する手があれば打ち歩詰めでない
        }
    }
    return true; // 王手を解除する手がなければ打ち歩詰め
}


/**
 * 局面pにおいて手番のある側が詰んでいるかどうかを返す
 */
bool inMate(Position p)
{
    Move[593] moves;
    int length = p.legalMoves(moves);
    foreach (Move move; moves[0..length]) {
        if (!p.doMove(move).doMove(Move.NULL_MOVE).inCheck) {
            return false;
        }
    }
    return true;
}


/**
 * 局面pにおいて手番のある側が王手をかけられているかどうかを返す
 */
bool inCheck(Position p)
{
    // 相手の駒を動かして自玉が取られるようなら王手をかけられている
    for (Address from = Address.of11; from.i <= Address.of99.i; from = from.succ) {
        if (!p.board[from.i].isEnemyOf(p.sideToMove)) {
            continue;
        }
        foreach (Dir d; DIRECTIONS[p.board[from.i].i]) {
            for (Address to = from.go(d); to != Address.INVALID && (p.board[to.i] == Square.EMPTY || p.board[to.i].isFriendOf(p.sideToMove)); to = to.go(d)) {
                if (p.board[to.i].type == Type.KING) {
                    return true;
                }
                if (!d.isFly || p.board[to.i].isFriendOf(p.sideToMove)) {
                    break;
                }
            }
        }
    }
    return false;
}

/**
 * 駒を取る手を生成する
 * returns: 生成した数
 */
int capturelMoves(ref Position p, Move[] outMoves)
{
    if (p.piecesInHand[Color.BLACK][Type.KING.i] > 0 || p.piecesInHand[Color.WHITE][Type.KING.i] > 0) {
        return 0;
    }

    // 盤上の駒を動かす
    int length = 0;
    for (Address from = Address.of11; from.i <= Address.of99.i; from = from.succ) {
        if (!p.board[from.i].isFriendOf(p.sideToMove)) {
            continue;
        }
        foreach (Dir d; DIRECTIONS[p.board[from.i].i]) {
            for (Address to = from.go(d); to != Address.INVALID && (p.board[to.i] == Square.EMPTY || p.board[to.i].isEnemyOf(p.sideToMove)); to = to.go(d)) {
                if (p.board[to.i].isEnemyOf(p.sideToMove)) {
                    if (canPromote(p.board[from.i], from, to)) {
                        outMoves[length++] = Move.createPromote(from, to);
                        if (p.board[from.i].type == Type.SILVER
                            || ((to.rank == 3 || to.rank == 7) && (p.board[from.i].type == Type.LANCE || p.board[from.i].type == Type.KNIGHT))) {
                            outMoves[length++] = Move.createMove(from, to); // 銀か, 3段目,7段目の香,桂なら不成も生成する
                        }
                    } else if (RANK_MIN[p.board[from.i].i] <= to.rank && to.rank <= RANK_MAX[p.board[from.i].i]) {
                        outMoves[length++] = Move.createMove(from, to);
                    }
                    break;
                }
                if (!d.isFly) {
                    break;
                }
            }
        }
    }
    return length;
}

/**
 * 合法手を生成する
 * returns: 生成した数
 */
int legalMoves(ref Position p, Move[] outMoves)
{
    if (p.piecesInHand[Color.BLACK][Type.KING.i] > 0 || p.piecesInHand[Color.WHITE][Type.KING.i] > 0) {
        return 0;
    }

    bool[10] pawned = false; // 0～9筋に味方の歩があるか

    // 駒を取る手を生成する
    int length = p.capturelMoves(outMoves);

    // 盤上の駒を動かす
    for (Address from = Address.of11; from.i <= Address.of99.i; from = from.succ) {
        if (!p.board[from.i].isFriendOf(p.sideToMove)) {
            continue;
        }
        pawned[from.file] |= (p.board[from.i].type == Type.PAWN);
        foreach (Dir d; DIRECTIONS[p.board[from.i].i]) {
            for (Address to = from.go(d); to != Address.INVALID && p.board[to.i] == Square.EMPTY; to = to.go(d)) {
                if (canPromote(p.board[from.i], from, to)) {
                    outMoves[length++] = Move.createPromote(from, to);
                    if (p.board[from.i].type == Type.SILVER
                        || ((to.rank == 3 || to.rank == 7) && (p.board[from.i].type == Type.LANCE || p.board[from.i].type == Type.KNIGHT))) {
                        outMoves[length++] = Move.createMove(from, to); // 銀か, 3段目,7段目の香,桂なら不成も生成する
                    }
                } else if (RANK_MIN[p.board[from.i].i] <= to.rank && to.rank <= RANK_MAX[p.board[from.i].i]) {
                    outMoves[length++] = Move.createMove(from, to);
                }
                if (!d.isFly) {
                    break; // 飛び駒でなければここでbreak
                }
            }
        }
    }

    // 持ち駒を打つ
    for (Address to = Address.of11; to.i <= Address.of99.i; to = to.succ) {
        if (p.board[to.i] != Square.EMPTY) {
            continue;
        }
        for (uint8_t t = (pawned[to.file] ? Type.LANCE.i : Type.PAWN.i); t <= Type.ROOK.i; t++) { // 歩,香,桂,銀,金,角,飛
            if (p.piecesInHand[p.sideToMove][t] > 0 && to.rank >= RANK_MIN[Square(p.sideToMove, Type(t)).i] && RANK_MAX[Square(p.sideToMove, Type(t)).i] >= to.rank) {
                outMoves[length++] = Move.createDrop(Type(t), to);
            }
        }
    }
    return length;
}

private bool canPromote(Square sq, Address from, Address to)
{
    return sq.isPromotable && (sq.isBlack ? (from.rank <= 3 || to.rank <= 3) : (from.rank >= 7 || to.rank >= 7));
}

private immutable Dir[][] DIRECTIONS = [
    [ Dir.N  ],                                                             //  0:B_PAWN
    [ Dir.FN ],                                                             //  1:B_LANCE
    [ Dir.NNE, Dir.NNW ],                                                   //  2:B_KNIGHT
    [ Dir.N,   Dir.NE,  Dir.NW,  Dir.SE,  Dir.SW ],                         //  3:B_SILVER
    [ Dir.N,   Dir.NE,  Dir.NW,  Dir.E,   Dir.W,  Dir.S ],                  //  4:B_GOLD
    [ Dir.FNE, Dir.FNW, Dir.FSE, Dir.FSW ],                                 //  5:B_BISHOP
    [ Dir.FN,  Dir.FE,  Dir.FW,  Dir.FS  ],                                 //  6:B_ROOK
    [ Dir.N,   Dir.NE,  Dir.NW,  Dir.E,   Dir.W,  Dir.S,  Dir.SE, Dir.SW ], //  7:B_KING
    [ Dir.N,   Dir.NE,  Dir.NW,  Dir.E,   Dir.W,  Dir.S ],                  //  8:B_PROMOTED_PAWN
    [ Dir.N,   Dir.NE,  Dir.NW,  Dir.E,   Dir.W,  Dir.S ],                  //  9:B_PROMOTED_LANCE
    [ Dir.N,   Dir.NE,  Dir.NW,  Dir.E,   Dir.W,  Dir.S ],                  // 10:B_PROMOTED_KNIGHT
    [ Dir.N,   Dir.NE,  Dir.NW,  Dir.E,   Dir.W,  Dir.S ],                  // 11:B_PROMOTED_SILVER
    [ Dir.FNE, Dir.FNW, Dir.FSE, Dir.FSW, Dir.N,  Dir.E,  Dir.W,  Dir.S  ], // 12:B_PROMOTED_BISHOP
    [ Dir.FN,  Dir.FE,  Dir.FW,  Dir.FS,  Dir.NE, Dir.NW, Dir.SE, Dir.SW ], // 13:B_PROMOTED_ROOK
    [ Dir.S  ],                                                             // 14:W_PAWN
    [ Dir.FS ],                                                             // 15:W_LANCE
    [ Dir.SSW, Dir.SSE ],                                                   // 16:W_KNIGHT
    [ Dir.S,   Dir.SW,  Dir.SE,  Dir.NW,  Dir.NE ],                         // 17:W_SILVER
    [ Dir.S,   Dir.SW,  Dir.SE,  Dir.W,   Dir.E,  Dir.N ],                  // 18:W_GOLD
    [ Dir.FSW, Dir.FSE, Dir.FNW, Dir.FNE ],                                 // 19:W_BISHOP
    [ Dir.FS,  Dir.FW,  Dir.FE,  Dir.FN  ],                                 // 20:W_ROOK
    [ Dir.S,   Dir.SW,  Dir.SE,  Dir.W,   Dir.E,  Dir.N,  Dir.NW, Dir.NE ], // 21:W_KING
    [ Dir.S,   Dir.SW,  Dir.SE,  Dir.W,   Dir.E,  Dir.N ],                  // 22:W_PROMOTED_PAWN
    [ Dir.S,   Dir.SW,  Dir.SE,  Dir.W,   Dir.E,  Dir.N ],                  // 23:W_PROMOTED_LANCE
    [ Dir.S,   Dir.SW,  Dir.SE,  Dir.W,   Dir.E,  Dir.N ],                  // 24:W_PROMOTED_KNIGHT
    [ Dir.S,   Dir.SW,  Dir.SE,  Dir.W,   Dir.E,  Dir.N ],                  // 25:W_PROMOTED_SILVER
    [ Dir.FSW, Dir.FSE, Dir.FNW, Dir.FNE, Dir.S,  Dir.W,  Dir.E,  Dir.N  ], // 26:W_PROMOTED_BISHOP
    [ Dir.FS,  Dir.FW,  Dir.FE,  Dir.FN,  Dir.SW, Dir.SE, Dir.NW, Dir.NE ], // 27:W_PROMOTED_ROOK
];

// ▲歩,香,桂,銀,金,角,飛,王,と,成香,成桂,成銀,馬,龍,△歩,香,桂,銀,金,角,飛,王,と,成香,成桂,成銀,馬,龍
private immutable ubyte[] RANK_MIN = [
    2, 2, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
];

// ▲歩,香,桂,銀,金,角,飛,王,と,成香,成桂,成銀,馬,龍,△歩,香,桂,銀,金,角,飛,王,と,成香,成桂,成銀,馬,龍
private immutable ubyte[] RANK_MAX = [
    9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
    8, 8, 7, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
];
