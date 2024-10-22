module main;

import std.stdio;
import std.datetime;
import std.string;
import std.regex;
import std.conv : to;
import core.thread;
import core.sys.posix.unistd : getpid;

import types, book, eval, search, position, movegen;


__gshared File logFile;
__gshared string[string] options;
__gshared Position _position;


void send(string line)
{
    log(getpid().to!string ~ " " ~ Clock.currTime().toISOExtString() ~ " > " ~ line);
    writeln(line);
    stdout.flush();
}

void log(string line)
{
    logFile.writeln(line);
    logFile.flush();
}

void on_usi(string line)
{
    send("id name 手抜き");
    send("id author 手抜きチーム");
    send("option name USI_Hash type spin default 0");
    send("option name USI_Ponder type check default false");
    send("option name Depth type spin default 1 min -1 max 1");
    send("usiok");
}

void on_isready(string line)
{
    send("readyok");
}

void on_position(string line)
{
    auto parts = line.split();
    string sfen_or_startpos = parts[1];
    auto m = line.matchFirst(regex(r"moves (.*)$"));
    string moves = !m.empty ? m.captures[1] : null;

    _position = Position.create("sfen lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1");

    foreach (move; moves.split()) {
        Move hoge = Move.parseUsi(move);
        log(hoge.toString(_position));
        log(hoge.toString(_position, FORMAT.USI));

        _position = _position.doMove(hoge);
        log(_position.toString);

    }
}

void on_setoption(string line)
{
    auto parts = line.split();
    string name = parts[2];
    string value = parts[4];
    options[name] = value;
    log("setoption: " ~ options.to!string);
}


void on_go(string line)
{
    log("on_go");

    Thread.sleep(dur!("msecs")(1000));

    Move m = _position.ponder();
    send("bestmove " ~ m.toString(_position, FORMAT.USI));
}






void main()
{

    //
    //Position p = Position.create("sfen 1n6k/2s1ggrB1/3pGp1LS/LSp1S2+B1/4p4/1p4L2/2PPPPP1N/1GK5p/6R2 w N7Pnl 109");
    //writeln(p);
    //
    //Move m = p.ponder();
    //writeln(m.toString(p));
    //p = p.doMove(m);
    //writeln(p);
    //p = p.doMove(Move.NULL_MOVE);
    //writeln(p);
    //writeln(p.inCheck);
    //
    ////
    //foreach (m; pv) {
    //    writeln(m.toString(p));
    //}
    //
    //
    //writeln(p.toString);



    try {
        logFile = File("log.txt", "a");

        foreach (line; stdin.byLineCopy()) {
            line = line.chomp();
            log(getpid().to!string ~ " " ~ Clock.currTime().toISOExtString() ~ " < " ~ line);

            if (line == "usi") {
                on_usi(line);
            } else if (line == "isready") {
                on_isready(line);
            } else if (line.startsWith("setoption ")) {
                on_setoption(line);
            } else if (line == "usinewgame") {
                log("usinewgamed");
            } else if (line.startsWith("position ")) {
                on_position(line);
            } else if (line.startsWith("go ")) {
                on_go(line);
                //log("gone");
                //send("bestmove 8c8d");
            } else if (line == "stop") {
                log("stop: not implemented");
            } else if (line == "ponderhit") {
                log("ponderhit: not implemented");
            } else if (line == "quit") {
                log("quitting");
                return; // プログラムを終了
            } else if (line.startsWith("gameover ")) {
                log("gameovered");
            } else {
                log(line ~ ": unsupported command");
            }
        }
    } catch (Throwable e) {
        log(e.msg);
    }
}
