module book;

import movegen;
import std.random;
import std.regex;
import std.stdio;
import std.string;
import types, position;


immutable Move[][string] BOOK;


shared static this()
{
    File f = File("book.db", "r");
    scope(exit) f.close();

    Position p = Position.create;

    string line;
    string key;
    while ((line = f.readln()) !is null) {
        line = line.strip;
        if (line.matchFirst(r"^#")) {
            continue;
        }
        if (line.matchFirst(r"^sfen ")) {
            key = line;
        } else {
            BOOK[key] ~= Move.parseUsi(line);
        }
    }

}


struct BookPos
{
    Move bestMove;
    Move nextMove;
    int value;
    int depth;
    int num;
}


Move pick(ref Position p)
{
    string sfen = p.sfen;
    if (sfen in book.BOOK) {
        return book.BOOK[sfen][ uniform(0, book.BOOK[sfen].length) ];
    }
    return Move.NULL;
}


void dump()
{
    foreach (key, value; BOOK) {
        writeln(key);
        foreach (move; value) {
            writeln(move);
        }
    }
}


void validateBook()
{
    foreach (sfen, moves; BOOK) {
        Position p = Position.create(sfen);
        assert(sfen == p.sfen);
        foreach (Move move; moves) {
            if (!move.isValid(p)) {
                stderr.writeln(p.toString);
                stderr.writefln("%02d%02d", (move.i >> 7) & 0b1111111, move.i & 0b1111111);
            }
        }
    }
}
