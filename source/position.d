module tenuki.position;

import std.array;
import std.conv;
import std.format;
import std.stdint;
import std.regex;
import std.string;
import std.ascii;
import tenuki.types;


/**
 * 局面
 */
struct Position
{
    Square[81] board;
    uint8_t[8][2] piecesInHand;
    bool sideToMove;
    uint16_t moveCount = 1;
    Move previousMove; // 直前の指し手

    /**
     * 局面に指し手を適用した新しい局面を生成して返す
     */
    Position doMove(Move m)
    {
        Position p = this;

        import std.stdio;

        if (m != Move.NULL_MOVE && m != Move.TORYO) {
            if (m.isDrop) {
                Type t = m.type;
                p.board[m.to.i] = Square(p.sideToMove, t);
                p.piecesInHand[p.sideToMove][t.i]--;
            } else {
                // capture
                if (p.board[m.to.i] != Square.EMPTY) {
                    Type t = p.board[m.to.i].baseType;
                    p.piecesInHand[p.sideToMove][t.i]++;
                }
                p.board[m.to.i] = m.isPromote ? p.board[m.from.i].promote : p.board[m.from.i];
                p.board[m.from.i] = Square.EMPTY;
            }
        }
        p.sideToMove ^= 1;
        p.moveCount++;
        p.previousMove = m;
        return p;
    }

    string toString()
    {
        return format("%s\n%s\n", this.sfen, this.toKi2());
    }

    /**
     * SFEN形式の文字列を返す
     */
    string sfen()
    {
        string[] lines;
        for (int rank = 0; rank <= 8; rank++) {
            string line;
            for (int file = 8; file >= 0; file--) {
                line ~= this.board[file * 9 + rank].toSfenString;
            }
            lines ~= line;
        }
        string board = lines.join("/");
        for (int i = 9; i >= 2; i--) {
            board = board.replace("1".replicate(i), to!string(i)); // '1'をまとめる
        }

        string side = (this.sideToMove == Color.BLACK ? "b" : "w");

        // 飛車, 角, 金, 銀, 桂, 香, 歩
        string hand;
        foreach (color_t c; [Color.BLACK, Color.WHITE]) {
            foreach (Type t; [Type.KING, Type.ROOK, Type.BISHOP, Type.GOLD, Type.SILVER, Type.KNIGHT, Type.LANCE, Type.PAWN]) {
                int n = this.piecesInHand[c][t.i];
                if (n > 0) {
                    hand ~= (n > 1 ? to!string(n) : "") ~ Square(c, t).toSfenString;
                }
            }
        }
        if (hand == "") {
            hand = "-";
        }

        return format("sfen %s %s %s %s", board, side, hand, this.moveCount);
    }

    /**
     * pのKI2形式の文字列を返す
     */
    string toKi2()
    {
        immutable string[] HAND = [
            "歩", "香", "桂", "銀", "金", "角", "飛", "玉",
        ];

        immutable string[] NUM = [
            "〇", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八",
        ];

        string[2] hand;
        foreach (color_t s; [Color.BLACK, Color.WHITE]) {
            foreach (Type t; [Type.KING, Type.ROOK, Type.BISHOP, Type.GOLD, Type.SILVER, Type.KNIGHT, Type.LANCE, Type.PAWN]) {
                int n = this.piecesInHand[s][t.i];
                if (n > 0) {
                    hand[s] ~= format("%s%s　", HAND[t.i], (n > 1 ? NUM[n] : ""));
                }
            }
        }

        string s;
        s ~= format("後手の持駒：%s\n", (hand[Color.WHITE] == "" ? "なし" : hand[Color.WHITE]));
        s ~= "  ９ ８ ７ ６ ５ ４ ３ ２ １\n";
        s ~= "+---------------------------+\n";
        for (int rank = 0; rank <= 8; rank++) {
            s ~= "|";
            for (int file = 8; file >= 0; file--) {
                s ~= this.board[file * 9 + rank].toKi2String;
            }
            s ~= format("|%s\n", NUM[rank + 1]);
        }
        s ~= "+---------------------------+\n";
        s ~= format("先手の持駒：%s\n", (hand[Color.BLACK] == "" ? "なし" : hand[Color.BLACK]));
        return s;
    }


    static Position create(string sfen = "sfen lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1")
    {
        Position p;
        p.board = Square.EMPTY;

        string[] ss = sfen.strip().split(regex(r"\s+"));
        if (ss[0] != "sfen") {
            throw new StringException(sfen);
        }
        string boardState = ss[1];
        string sideToMove = ss[2];
        string piecesInHand = ss[3];
        string moveCount = ss[4];

        p.moveCount = to!short(moveCount);

        // 手番
        if (sideToMove != "b" && sideToMove != "w") {
            throw new StringException(sfen);
        }
        p.sideToMove = sideToMove == "b" ? Color.BLACK : Color.WHITE;

        // 盤面
        for (int i = 9; i >= 2; i--) {
            boardState = boardState.replace(to!string(i), "1".replicate(i)); // 2～9を1に開いておく
        }
        boardState = boardState.replace("/", "");
        auto m = boardState.matchAll(r"\+?.");
        for (int rank = 0; rank <= 8; rank++) {
            for (int file = 8; file >= 0; file--) {
                p.board[file * 9 + rank] = Square.parse(m.front.hit);
                m.popFront();
            }
        }

        // 持ち駒
        if (piecesInHand != "-") {
            // 例：S, 4P, b, 3n, p, 18P
            foreach (c; piecesInHand.matchAll(r"(\d*)(\D)")) {
                int num = (c[1] == "") ? 1 : to!int(c[1]);
                string piece = c[2];
                p.piecesInHand[piece[0].isUpper() ? Color.BLACK : Color.WHITE][Type.parse(piece).i] += num;
            }
        }
        return p;
    }
}

unittest
{
    Position p = Position.create;
    assert(p.sfen == "sfen lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1");
}
