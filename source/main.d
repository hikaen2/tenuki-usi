module tenuki.main;

import std.stdio;
import std.datetime;
import std.string;
import std.regex;
import std.conv : to;
import std.process : thisProcessID;

import tenuki.types, tenuki.eval, tenuki.search, tenuki.position, tenuki.movegen;

__gshared File logFile;
__gshared Position position;

void main()
{
    try {
        logFile = File("log.txt", "a");

        foreach (line; stdin.byLineCopy()) {
            line = line.chomp();
            log(thisProcessID.to!string ~ " " ~ Clock.currTime().toISOExtString() ~ " < " ~ line);

            if (line == "usi") {
                on_usi(line);
            } else if (line == "isready") {
                on_isready(line);
            } else if (line.startsWith("setoption ")) {
                on_setoption(line);
            } else if (line == "usinewgame") {
                on_usinewgame(line);
            } else if (line.startsWith("position ")) {
                on_position(line);
            } else if (line.startsWith("go ")) {
                on_go(line);
            } else if (line == "stop") {
                on_stop(line);
            } else if (line == "ponderhit") {
                on_ponderhit(line);
            } else if (line == "quit") {
                log("quitting");
                return; // プログラムを終了
            } else if (line.startsWith("gameover ")) {
                on_gameover(line);
            } else {
                log(line ~ ": unsupported command");
            }
        }
    } catch (Throwable e) {
        log(e.msg);
    }
}

void send(string line)
{
    log(thisProcessID.to!string ~ " " ~ Clock.currTime().toISOExtString() ~ " > " ~ line);
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
    send("id name Tenuki");
    send("id author Tenuki team");
    send("option name USI_Hash type spin default 0");
    send("option name USI_Ponder type check default false");
    send("option name Depth type spin default 1 min -1 max 4");
    send("option name Q_Depth type spin default 0 min 0 max 4");
    send("option name Wait type check default false");
    send("usiok");
}

void on_isready(string line)
{
    send("readyok");
}

void on_position(string line)
{
    log("on_position");

    auto parts = line.split();
    string sfen_or_startpos = parts[1];
    auto m = line.matchFirst(regex(r"moves (.*)$"));
    string moves = !m.empty ? m.captures[1] : null;

    position = Position.create;
    foreach (move; moves.split) {
        Move mv = Move.parse(move);
        log(mv.toString);

        position = position.doMove(mv);
    }
    log(position.toString);
}

void on_setoption(string line)
{
    log("on_setoption");

    auto parts = line.split();
    string name = parts[2];
    string value = parts[4];

    if (name == "Depth") Options.depth = value.to!int;
    if (name == "Q_Depth") Options.q_depth = value.to!int;
    if (name == "Wait") Options.wait = value.to!bool;
}

void on_usinewgame(string line)
{
    log("on_usinewgame");
}

void on_go(string line)
{
    log("on_go");

    import core.thread : Thread;
    if (Options.wait) Thread.sleep(dur!("msecs")(1000));

    Move m = position.ponder();
    send("bestmove " ~ m.toString);
}

void on_stop(string line)
{
    log("stop: not implemented");
}

void on_ponderhit(string line)
{
    log("ponderhit: not implemented");
}

void on_gameover(string line)
{
    log("on_gameover");
}
