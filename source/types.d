module tenuki.types;

import std.array;
import std.conv;
import std.format;
import std.stdint;
import std.regex;
import std.string;
import std.ascii;
import tenuki.position;

alias color_t = uint8_t;

enum FORMAT { CSA, USI }


/**
 * 手番を表す列挙体
 */
enum Color : color_t
{
    BLACK = 0, // 先手
    WHITE = 1, // 後手
    NONE  = 2,
}


/**
 * 盤面のアドレスを表す型
 *
 *  9  8  7  6  5  4  3  2  1
 * --------------------------+
 * 72 63 54 45 36 27 18  9 0 | 一 a
 * 73 64 55 46 37 28 19 10 1 | 二 b
 * 74 65 56 47 38 29 20 11 2 | 三 c
 * 75 66 57 48 39 30 21 12 3 | 四 d
 * 76 67 58 49 40 31 22 13 4 | 五 e
 * 77 68 59 50 41 32 23 14 5 | 六 f
 * 78 69 60 51 42 33 24 15 6 | 七 g
 * 79 70 61 52 43 34 25 16 7 | 八 h
 * 80 71 62 53 44 35 26 17 8 | 九 i
 */
struct Address
{
    uint8_t i;

    enum _11 = Address.parse("11");
    enum _99 = Address.parse("99");

    this(int i)
    {
        this.i = cast(uint8_t)i;
    }

    int file()
    {
        immutable FILE = [
            1, 1, 1, 1, 1, 1, 1, 1, 1,
            2, 2, 2, 2, 2, 2, 2, 2, 2,
            3, 3, 3, 3, 3, 3, 3, 3, 3,
            4, 4, 4, 4, 4, 4, 4, 4, 4,
            5, 5, 5, 5, 5, 5, 5, 5, 5,
            6, 6, 6, 6, 6, 6, 6, 6, 6,
            7, 7, 7, 7, 7, 7, 7, 7, 7,
            8, 8, 8, 8, 8, 8, 8, 8, 8,
            9, 9, 9, 9, 9, 9, 9, 9, 9,
        ];
        return FILE[i]; // 1から9を返す
    }

    int rank() {
        immutable RANK = [
            1, 2, 3, 4, 5, 6, 7, 8, 9,
            1, 2, 3, 4, 5, 6, 7, 8, 9,
            1, 2, 3, 4, 5, 6, 7, 8, 9,
            1, 2, 3, 4, 5, 6, 7, 8, 9,
            1, 2, 3, 4, 5, 6, 7, 8, 9,
            1, 2, 3, 4, 5, 6, 7, 8, 9,
            1, 2, 3, 4, 5, 6, 7, 8, 9,
            1, 2, 3, 4, 5, 6, 7, 8, 9,
            1, 2, 3, 4, 5, 6, 7, 8, 9,
        ];
        return RANK[i]; // 1から9を返す
    }

    string toString() {
        return format("%s%s", file(), cast(char)('a' + rank() - 1)); // "1a" から "9i" を返す
    }

    static Address parse(string s)
    {
        int file = s[0..1].to!int;
        int rank = s[1].isDigit ? s[1..2].to!int :  s[1] - 'a' + 1;
        return Address(cast(uint8_t)((file - 1) * 9 + rank - 1));
    }
}

unittest
{
    Address a = Address.parse("2f");
    assert(a.i == 14);
    assert(a.file == 2);
    assert(a.rank == 6);
    assert(a.toString == "2f");
}


/**
 * 駒の種類を表す型
 * 手番を含まない
 */
struct Type
{
    uint8_t i;

    enum PAWN            = Type(0);  // 歩
    enum LANCE           = Type(1);  // 香
    enum KNIGHT          = Type(2);  // 桂
    enum SILVER          = Type(3);  // 銀
    enum GOLD            = Type(4);  // 金
    enum BISHOP          = Type(5);  // 角
    enum ROOK            = Type(6);  // 飛
    enum KING            = Type(7);  // 王
    enum PROMOTED_PAWN   = Type(8);  // と
    enum PROMOTED_LANCE  = Type(9);  // 成香
    enum PROMOTED_KNIGHT = Type(10); // 成桂
    enum PROMOTED_SILVER = Type(11); // 成銀
    enum PROMOTED_BISHOP = Type(12); // 馬
    enum PROMOTED_ROOK   = Type(13); // 龍
    enum EMPTY           = Type(14); // 空

    private enum string[] USI = ["P", "L", "N", "S", "G", "B", "R", "K", "+P", "+L", "+N", "+G", "+B", "+R", ""];

    string toString()
    {
        return USI[i];
    }

    static parse(string s)
    {
        import std.algorithm : countUntil;
        return Type(cast(uint8_t)USI.countUntil(s.toUpper));
    }
}

unittest
{
    assert(Type.parse("+p") == Type.PROMOTED_PAWN);
    assert(Type.PAWN.toString == "P");
}


/**
 * 盤面の升の状態を表す構造体.
 * Positionにはこれが81個ある.
 */
struct Square
{
    uint8_t i;

    enum B_PAWN            = Square(0);
    enum B_LANCE           = Square(1);
    enum B_KNIGHT          = Square(2);
    enum B_SILVER          = Square(3);
    enum B_GOLD            = Square(4);
    enum B_BISHOP          = Square(5);
    enum B_ROOK            = Square(6);
    enum B_KING            = Square(7);
    enum B_PROMOTED_PAWN   = Square(8);
    enum B_PROMOTED_LANCE  = Square(9);
    enum B_PROMOTED_KNIGHT = Square(10);
    enum B_PROMOTED_SILVER = Square(11);
    enum B_PROMOTED_BISHOP = Square(12);
    enum B_PROMOTED_ROOK   = Square(13);
    enum W_PAWN            = Square(14);
    enum W_LANCE           = Square(15);
    enum W_KNIGHT          = Square(16);
    enum W_SILVER          = Square(17);
    enum W_GOLD            = Square(18);
    enum W_BISHOP          = Square(19);
    enum W_ROOK            = Square(20);
    enum W_KING            = Square(21);
    enum W_PROMOTED_PAWN   = Square(22);
    enum W_PROMOTED_LANCE  = Square(23);
    enum W_PROMOTED_KNIGHT = Square(24);
    enum W_PROMOTED_SILVER = Square(25);
    enum W_PROMOTED_BISHOP = Square(26);
    enum W_PROMOTED_ROOK   = Square(27);
    enum EMPTY             = Square(28);

    //   歩,  香,  桂,  銀,  金,  角,  飛,  王,   と, 成香, 成桂, 成銀,   馬,   龍,
    private enum string[] SFEN = [
        "P", "L", "N", "S", "G", "B", "R", "K", "+P", "+L", "+N", "+S", "+B", "+R",
        "p", "l", "n", "s", "g", "b", "r", "k", "+p", "+l", "+n", "+s", "+b", "+r", "1",
    ];

    private enum string[] KI2 = [
        " 歩", " 香", " 桂", " 銀", " 金", " 角", " 飛", " 玉", " と", " 杏", " 圭", " 全", " 馬", " 龍",
        "v歩", "v香", "v桂", "v銀", "v金", "v角", "v飛", "v玉", "vと", "v杏", "v圭", "v全", "v馬", "v龍", " ・",
    ];

    private enum color_t[] COLOR = [
        Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK,
        Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK,
        Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE,
        Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE,
        Color.NONE,
    ];

    this(int i)
    {
        this.i = cast(uint8_t)i;
    }

    this(color_t c, Type t)
    {
        this.i = cast(uint8_t)(c * Square.W_PAWN.i + t.i);
    }

    bool isBlack()
    {
        return COLOR[i] == Color.BLACK;
    }

    bool isWhite()
    {
        return COLOR[i] == Color.WHITE;
    }

    bool isFriendOf(color_t c)
    {
        return COLOR[i] == c;
    }

    bool isEnemyOf(color_t c)
    {
        return COLOR[i] == (c ^ 1);
    }

    bool isPromotable()
    {
        immutable PROMOTABLE = [
            true, true, true, true, false, true, true, false, false, false, false, false, false, false,
            true, true, true, true, false, true, true, false, false, false, false, false, false, false,
            false,
        ];
        return PROMOTABLE[i];
    }

    Type type()
    {
        immutable TYPE = [
            Type.PAWN, Type.LANCE, Type.KNIGHT, Type.SILVER, Type.GOLD, Type.BISHOP, Type.ROOK, Type.KING,
            Type.PROMOTED_PAWN, Type.PROMOTED_LANCE, Type.PROMOTED_KNIGHT, Type.PROMOTED_SILVER, Type.PROMOTED_BISHOP, Type.PROMOTED_ROOK,
            Type.PAWN, Type.LANCE, Type.KNIGHT, Type.SILVER, Type.GOLD, Type.BISHOP, Type.ROOK, Type.KING,
            Type.PROMOTED_PAWN, Type.PROMOTED_LANCE, Type.PROMOTED_KNIGHT, Type.PROMOTED_SILVER, Type.PROMOTED_BISHOP, Type.PROMOTED_ROOK,
            Type.EMPTY
        ];
        return TYPE[i];
    }

    Type baseType()
    {
        immutable BASETYPE = [
            Type.PAWN, Type.LANCE, Type.KNIGHT, Type.SILVER, Type.GOLD, Type.BISHOP, Type.ROOK, Type.KING,
            Type.PAWN, Type.LANCE, Type.KNIGHT, Type.SILVER, Type.BISHOP, Type.ROOK,
            Type.PAWN, Type.LANCE, Type.KNIGHT, Type.SILVER, Type.GOLD, Type.BISHOP, Type.ROOK, Type.KING,
            Type.PAWN, Type.LANCE, Type.KNIGHT, Type.SILVER, Type.BISHOP, Type.ROOK,
            Type.EMPTY
        ];
        return BASETYPE[i];
    }

    Square promote()
    {
        immutable PROMOTE = [
            Square.B_PROMOTED_PAWN, Square.B_PROMOTED_LANCE, Square.B_PROMOTED_KNIGHT, Square.B_PROMOTED_SILVER, Square.B_GOLD, Square.B_PROMOTED_BISHOP, Square.B_PROMOTED_ROOK, Square.B_KING,
            Square.B_PROMOTED_PAWN, Square.B_PROMOTED_LANCE, Square.B_PROMOTED_KNIGHT, Square.B_PROMOTED_SILVER, Square.B_PROMOTED_BISHOP, Square.B_PROMOTED_ROOK,
            Square.W_PROMOTED_PAWN, Square.W_PROMOTED_LANCE, Square.W_PROMOTED_KNIGHT, Square.W_PROMOTED_SILVER, Square.W_GOLD, Square.W_PROMOTED_BISHOP, Square.W_PROMOTED_ROOK, Square.W_KING,
            Square.W_PROMOTED_PAWN, Square.W_PROMOTED_LANCE, Square.W_PROMOTED_KNIGHT, Square.W_PROMOTED_SILVER, Square.W_PROMOTED_BISHOP, Square.W_PROMOTED_ROOK,
            Square.EMPTY,
        ];
        return PROMOTE[i];
    }

    Square inv()
    {
        immutable INV = [
            Square.W_PAWN, Square.W_LANCE, Square.W_KNIGHT, Square.W_SILVER, Square.W_GOLD, Square.W_BISHOP, Square.W_ROOK, Square.W_KING,
            Square.W_PROMOTED_PAWN, Square.W_PROMOTED_LANCE, Square.W_PROMOTED_KNIGHT, Square.W_PROMOTED_SILVER, Square.W_PROMOTED_BISHOP, Square.W_PROMOTED_ROOK,
            Square.B_PAWN, Square.B_LANCE, Square.B_KNIGHT, Square.B_SILVER, Square.B_GOLD, Square.B_BISHOP, Square.B_ROOK, Square.B_KING,
            Square.B_PROMOTED_PAWN, Square.B_PROMOTED_LANCE, Square.B_PROMOTED_KNIGHT, Square.B_PROMOTED_SILVER, Square.B_PROMOTED_BISHOP, Square.B_PROMOTED_ROOK,
            Square.EMPTY,
        ];
        return INV[i];
    }

    string toKi2String()
    {
        return KI2[i];
    }

    string toSfenString()
    {
        return SFEN[i];
    }

    static parse(string s)
    {
        import std.algorithm : countUntil;
        return Square(cast(uint8_t)SFEN.countUntil(s));
    }
}

unittest
{
    assert(Square.parse("P") == Square.B_PAWN);
    assert(Square.B_PAWN.toSfenString == "P");
    assert(Square.B_PAWN.inv == Square.W_PAWN);
}


/**
 * Direction
 *
 * 1111111x value
 * xxxxxxx1 fly
 */
struct Dir
{
    int8_t i;

    enum Dir N   = {-1 * 2}; // -1 << 1
    enum Dir E   = {-9 * 2}; // -9 << 1
    enum Dir W   = {+9 * 2}; // +9 << 1
    enum Dir S   = {+1 * 2}; // +1 << 1
    enum Dir NE  = {N.i + E.i};
    enum Dir NW  = {N.i + W.i};
    enum Dir SE  = {S.i + E.i};
    enum Dir SW  = {S.i + W.i};
    enum Dir NNE = {N.i + N.i + E.i};
    enum Dir NNW = {N.i + N.i + W.i};
    enum Dir SSE = {S.i + S.i + E.i};
    enum Dir SSW = {S.i + S.i + W.i};
    enum Dir FN  = {N.i | 1};
    enum Dir FE  = {E.i | 1};
    enum Dir FW  = {W.i | 1};
    enum Dir FS  = {S.i | 1};
    enum Dir FNE = {NE.i | 1};
    enum Dir FNW = {NW.i | 1};
    enum Dir FSE = {SE.i | 1};
    enum Dir FSW = {SW.i | 1};

    bool isFly() const { return (i & 1) != 0; }
    int  value() const { return i >> 1; }
}

/**
 * 指し手を表す型
 *
 * 1xxxxxxx xxxxxxxx promote
 * x1xxxxxx xxxxxxxx drop
 * xx111111 1xxxxxxx from
 * xxxxxxxx x1111111 to
 */
struct Move
{
    uint16_t i;

    enum Move NULL      = {0};
    enum Move NULL_MOVE = {0b00111111_11111110};
    enum Move TORYO     = {0b00111111_11111111};

    Type type()
    {
        //assert(isDrop);
        return cast(Type)((i >> 7) & 0b01111111);
    }

    Address from()
    {
        //assert(!isDrop);
        return cast(Address)((i >> 7) & 0b01111111);
    }

    Address to()
    {
        return cast(Address)(i & 0b01111111);
    }

    bool isPromote()
    {
        return (i & 0b1000000000000000) != 0;
    }

    bool isDrop()
    {
        return (i & 0b0100000000000000) != 0;
    }

    string toString()
    {
        if (this == Move.TORYO) {
            return "resign";
        }

        if (isDrop) {
            return this.type.toString ~ "*" ~ this.to.toString;
        } else {
            string moveStr;
            moveStr = from.toString ~ to.toString;
            if (isPromote) {
                moveStr ~= "+";
            }
            return moveStr;
        }
    }

    static Move createMove(Address from, Address to)
    {
        return Move(cast(uint16_t)(from.i << 7 | to.i));
    }

    static Move createPromote(Address from, Address to)
    {
        return Move(cast(uint16_t)(from.i << 7 | to.i | 0b1000000000000000));
    }

    static Move createDrop(Type t, Address to)
    {
        return Move(cast(uint16_t)(t.i << 7 | to.i | 0b0100000000000000));
    }

    /*
     * 7g7f
     * 8h2b+
     * G*5b
     */
    static Move parse(string s)
    {
        auto m = s.matchFirst(r"^(\D)\*(\d\D)");
        if (!m.empty) {
            return Move.createDrop(Type.parse(m[1]), Address.parse(m[2]));
        }

        m = s.matchFirst(r"^(\d\D)(\d\D)(\+?)");
        auto from = Address.parse(m[1]);
        auto to = Address.parse(m[2]);
        bool promote = (m[3] == "+");
        return promote ? Move.createPromote(from, to) : Move.createMove(from, to);
    }
}

unittest
{
    Move m = Move.parse("2g2f");
    assert(m.toString == "2g2f");
    assert(m.from == Address.parse("2g"));
    assert(m.to == Address.parse("2f"));
    assert(!m.isDrop);
    assert(!m.isPromote);
}

enum SQ11 = 0;
enum SQ99 = 80;


struct Options
{
    static int depth = 1;
    static int q_depth = 0;
    static bool wait = false;
}
