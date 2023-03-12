**free
ctl-opt main(main) dftactgrp(*no) actgrp(*caller);

dcl-f source usage(*input)
    extdesc('CLV1/QRPGLESRC')
    extfile(*extdesc)
    extmbr(#mbr)
    prefix(s_)
    usropn;

dcl-f evfevent usage(*input:*output:*update:*delete)
    extdesc('CLV1/EVFEVENT')
    extfile(#evfevent)
    extmbr(#mbr)
    rename(evfevent:revfevent)
    prefix(e_)
    usropn;

dcl-s #evfevent char(21);
dcl-s #mbr char(10);
dcl-s #z zoned(3);
dcl-s #add char(1);

dcl-ds #warnings qualified;
    number zoned(6) inz;
    isfree char(1) inz;
    freeline zoned(6) inz;
    ctloptfirstline zoned(6) inz;
    ctloptendline zoned(6) inz;
    dftactgrp char(1) inz;
    actgrp char(1) inz;
end-ds;

dcl-ds #errors qualified;
    number zoned(6) inz;
end-ds;

dcl-ds #line qualified;
    event char(11) inz('ERROR');            // Error information record
    number1 char(1) inz(*zeros);            // Version
    space1 char(1);
    number2 char(3) inz('001');             // File ID
    space2 char(1);
    number3 char(1) inz('0');               // Annot-class
    space3 char(1);
    number4 char(6) inz('000001');          // STMT line
    space4 char(1);
    number5 char(6) inz('000003');          // Start error line
    space5 char(1);
    number6 char(3) inz('001');             // Col.
    space6 char(1);
    number7 char(6) inz('000001');          // Lín.
    space7 char(1);
    number8 char(3) inz('000');
    space8 char(1);
    messageid char(7) inz('AS40001');
    space9 char(1);
    info char(1) inz('T');                 // I=  S=  T= ??
    space10 char(1);
    errorcode char(2) inz('30');
    space11 char(1);
    detail char(50) inz('001 This is TEST!!');
    buffer char(400) pos(1);
end-ds;

dcl-ds #details dim(*auto:1000) qualified;
    error char(2) inz;
    line char(3) inz;
    text char(50) inz;
end-ds;

dcl-ds #data dim(*auto:1000) qualified;
    #evfevent char(400);
end-ds;

// Main procedure
dcl-proc main;

    dcl-pi *n;
        #library char(10) const;
        #program char(10) const;
        #error ind;
    end-pi;

    // Possible errors added to structure
    #details(1).error = '00';
    #details(1).line = '001';
    #details(1).text = 'This is a FREE source';
    #details(2).error = '00';
    #details(2).line = '001';
    #details(2).text = 'This is NOT a FREE source';
    #details(3).error = '00';
    #details(3).line = '001';
    #details(3).text = 'CTL-OPT line must be written';
    #details(4).error = '00';
    #details(4).line = '001';
    #details(4).text = 'DFTACTGRP(*NO) must be written';
    #details(5).error = '00';
    #details(5).line = '001';
    #details(5).text = 'ACTGRP must be indicated';

    // The EVFEVENT file
    #evfevent = %trim(#library) + '/EVFEVENT';
    #mbr = #program;

    // Initialize the structure
    %elem(#data) = 0;
    #z = 0;
    #add = 'N';

    open EVFEVENT;
    // I look for "FILEEND" and insert before what i want...
    // I load the structure with the data that are in EVFEVENT
    dou %eof(EVFEVENT);
        read revfevent;
        if not %eof(EVFEVENT);
            if #add = 'N' and %subst(e_evfevent:1:5) = 'ERROR';
                #add = 'S';
            endif;
            if #add = 'S';
                #z += 1;
                #data(#z).#evfevent = e_evfevent;
                delete revfevent;
            endif;
        endif;
    enddo;
    close EVFEVENT;

    checksource();

    // If there are warnings of errors
    if #warnings.number > 0 or
       #errors.number > 0;

        open EVFEVENT;

        // Let's add the warnings
        if #warnings.number > 0;

            // **FREE warning
            if #warnings.isfree = 'Y';
                addError(1);
            else;
                addError(2);
            endif;
            // CTL-OPT warning
            if #warnings.ctloptfirstline <= 0;
                addError(3);
            endif;
            if #warnings.dftactgrp <> 'Y';
                addError(4);
            endif;
            if #warnings.actgrp <> 'Y';
                addError(5);
            endif;

        endif;

        for #z = 1 to %elem(#data);
            if %subst(#data(#z).#evfevent:49:7) = 'CPC5D07';
               iter;
            endif;
            e_evfevent = #data(#z).#evfevent;
            write revfevent;
        endfor;

        close EVFEVENT;

        if #errors.number > 0;
            snd-msg *escape %msg('RNS9310' : 'QDEVTOOLS/QRPGLEMSG' : #program)
            %target(*caller:2);
        endif;

    endif;

    *inlr = '1';

end-proc;

//
// addError procedure.  Adds error/warning to EVFEVENT
//
dcl-proc addError;
    dcl-pi *n;
        number zoned(4) const;
    end-pi;

    #line.errorcode = #details(number).error;
    #line.detail = #details(number).line + ' ' +
    #details(number).text;

    e_evfevent = #line.buffer;
    write revfevent;

end-proc;

//
// checksource procedure.  
// Checks source of the RPGLE program and finds the possible errors/warnings.
//
dcl-proc checksource;

    dcl-s #startline zoned(5) inz;
    dcl-s #lines zoned(5) inz;
    dcl-s pos zoned(5) inz;

    open SOURCE;

    dou %eof(SOURCE);
        read source;
        if not %eof(SOURCE);
            #lines += 1;
            if %len(%trim(s_srcdta)) <= 0;
                iter;
            endif;
            if #startline <= 0;
                #startline = #lines;
            endif;

            s_srcdta = %trim(s_srcdta);
            if %subst(s_srcdta:1:2) = '//';
                iter;
            endif;

            // Checks for **FREE line.
            if %upper(s_srcdta) = '**FREE';
                #warnings.isfree = 'Y';
                #warnings.number += 1;
                #warnings.freeline = #lines;
            endif;

            // Checks for CTL-OPT line.
            if %upper(%subst(s_srcdta:1:7)) = 'CTL-OPT';
                #warnings.ctloptfirstline = #lines;
            endif;
            if #warnings.ctloptfirstline > 0;
                if %scan(';':s_srcdta) > 0;
                    #warnings.ctloptendline = #lines;
                endif;
            endif;
            if #lines >= #warnings.ctloptfirstline and
                ((#warnings.ctloptendline > 0 and #lines <= #warnings.ctloptendline) or
                (#warnings.ctloptendline = 0));
                // Looks for dftactgrp(*no), must be there
                if %scan('DFTACTGRP(*NO)':%upper(s_srcdta)) > 0;
                    #warnings.dftactgrp = 'Y';
                endif;
                pos = %scan('ACTGRP(':%upper(s_srcdta));
                if (pos > 1 and %subst(%upper(s_srcdta):pos-1:1) <> 'T') or
                    pos = 1;
                    #warnings.actgrp = 'Y';
                endif;

            endif;
        endif;
    enddo;

    close SOURCE;

end-proc;