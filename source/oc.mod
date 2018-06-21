MODULE oc;
(*$CONSOLE*)

IMPORT
   Rtl := [Oberon07.Rtl],
   Out := [Oberon07.Out],
   Files := [Oberon07.Files],
   S := [Patchouli.Scanner],
   B := [Patchouli.Base],
   G := [Patchouli.Generator],
   P := [Patchouli.Parser];

VAR
   arg, fname: ARRAY 1024 OF CHAR;
   buildfile: Files.File;
   argIdx: INTEGER;
   buildMode, errFlag: BOOLEAN;

PROCEDURE Compile(fname: ARRAY OF CHAR);
   VAR
      srcfile: Files.File;
      modinit: B.Node;
      sym, startTime, endTime: INTEGER;
   BEGIN
      Out.String('Компилирую: '); Out.String(fname); Out.Ln;
      B.SetSrcPath(fname);
      srcfile := Files.Old(fname);
      S.Init(srcfile, 0);
      S.Get(sym);

      startTime := Rtl.Time();
      IF sym = S.module THEN
         modinit := P.Module()
      ELSE
         S.Mark('МОДУЛЬ?')
      END;
      IF S.errcnt = 0 THEN
         B.WriteSymfile;
         G.Generate(modinit);
         B.Cleanup;
         G.Cleanup;
         endTime := Rtl.Time()
      END;
      IF S.errcnt = 0 THEN
         Out.String('Размер кода: '); Out.Int(G.pc, 0); Out.Ln;
         Out.String('Размер глобальных переменных: '); Out.Int(G.varSize, 0); Out.Ln;
         Out.String('Размер статических данных: '); Out.Int(G.staticSize, 0); Out.Ln;
         Out.String('Время компиляции: ');
         Out.Int(Rtl.TimeToMSecs(endTime - startTime), 0);
         Out.String(' мсек'); Out.Ln
      END
   END Compile;

PROCEDURE ErrorNotFound(fname: ARRAY OF CHAR);
   BEGIN
      Out.String('Файл '); Out.String(fname);
      Out.String(' не найден'); Out.Ln
   END ErrorNotFound;

PROCEDURE Build(fname: ARRAY OF CHAR);
   VAR
      r: Files.Rider;
      i: INTEGER;
      x: BYTE;
      start, end: INTEGER;
      byteStr: ARRAY 1024 OF BYTE;
      srcfname: ARRAY 1024 OF CHAR;
   BEGIN
      start := Rtl.Time(); buildfile := Files.Old(fname);
      Files.Set(r, buildfile, 0); i := 0; Files.Read(r, x);
      WHILE ~r.eof DO
         WHILE (x <= 32) & ~r.eof DO Files.Read(r, x) END;
         WHILE (x > 32) & ~r.eof DO
            byteStr[i] := x; Files.Read(r, x); INC(i)
         END;
         IF i > 0 THEN
            byteStr[i] := 0; i := Rtl.Utf8ToUnicode(byteStr, srcfname);
            IF Files.Old(srcfname) # NIL THEN Compile(srcfname)
            ELSE ErrorNotFound(srcfname)
            END;
            Out.Ln; i := 0
         END
      END;
      end := Rtl.Time();
      Out.String('Общее время сборки: ');
      Out.Int(Rtl.TimeToMSecs(end-start), 0);
      Out.String(' мсек'); Out.Ln
   END Build;

(* -------------------------------------------------------------------------- *)
(* -------------------------------------------------------------------------- *)

PROCEDURE Get;
   BEGIN
      INC(argIdx);
      Rtl.GetArg(arg, argIdx)
   END Get;

PROCEDURE Mark(msg: ARRAY OF CHAR);
   BEGIN
      Out.String('арг '); Out.Int(argIdx, 0); Out.String(': ');
      Out.String(msg); Out.Ln;
      errFlag := TRUE
   END Mark;

PROCEDURE Arguments;

   PROCEDURE Option;
      BEGIN
         Rtl.LowerCase(arg);
         IF arg = '/b' THEN
            buildMode := TRUE;
            Get; Arguments
         ELSIF arg = '/sym' THEN
            Get;
            IF arg[0] = '/' THEN
               Mark('путь до symbols?'); Option
            ELSE
               B.SetSymPath(arg); Get; Arguments
            END
         ELSE (* unhandled *)
            Get; Arguments
         END
      END Option;

   BEGIN (* Arguments *)
      IF arg = 0X THEN (* end parsing *)
      ELSIF arg[0] # '/' THEN
         IF fname[0] = 0X THEN
            fname := arg
         ELSE
            Mark('другое имя файла?')
         END;
         Get; Arguments
      ELSIF arg[0] = '/' THEN Option
      END
   END Arguments;

PROCEDURE NotifyError(pos: INTEGER; msg: ARRAY OF CHAR);
   BEGIN
      Out.String('Поз '); Out.Int(pos, 0);
      Out.String(': '); Out.String(msg); Out.Ln
   END NotifyError;

BEGIN
   S.InstallNotifyError(NotifyError); Get; Arguments;
   IF fname[0] # 0X THEN
      IF Files.Old(fname) # NIL THEN
         IF ~buildMode THEN
            Compile(fname)
         ELSE
            Build(fname)
         END
      ELSE
         ErrorNotFound(fname)
      END
   ELSE
      Out.String('Компилятор Oberon-07 сброка 008'); Out.Ln;
      Out.String('Использование: oc <inputfile>'); Out.Ln
   END
END oc.
