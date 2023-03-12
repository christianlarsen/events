**free
ctl-opt main(events) dftactgrp(*no) actgrp(*caller)
copyright('EVENTS, (c)2023, Christian Larsen');

dcl-f source usage(*input)
    extdesc('QRPGLESRC')
    extfile(*extdesc)
    extmbr(#mbr)
    prefix(s_)
    usropn;

dcl-f evfevent usage(*input:*output:*update:*delete)
    extdesc('EVFEVENT')
    extfile(#evfevent)
    extmbr(#mbr)
    rename(evfevent:revfevent)
    prefix(e_)
    usropn;

dcl-f eve_code usage(*input)
    extdesc('EVE_CODE')
    extfile(*extdesc)
    keyed prefix(cod_);

dcl-s #evfevent char(21);
dcl-s #mbr char(10);

// Structure for warnings found
dcl-ds #warnings qualified;
    number zoned(6) inz;
    isfree char(1) inz;
    freeline zoned(6) inz;
    ctloptfirstline zoned(6) inz;
    ctloptendline zoned(6) inz;
    nodebugio char(1) inz;
    inlr char(1) inz;
end-ds;

// Structure for errors found
dcl-ds #errors qualified;
    number zoned(6) inz;
    dftactgrp char(1) inz;
    actgrp char(1) inz;
end-ds;

// Structure of EVFEVENT file
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

// Structure for saving information from EVFEVENT file
dcl-ds #data dim(*auto:10000) qualified;
    #evfevent char(400);
end-ds;

//
// Main procedure
//
dcl-proc events;

    dcl-pi events;
        #library char(10) const;
        #program char(10) const;
        #error ind;
    end-pi;
    dcl-s #z zoned(3);
    dcl-s #add char(10);

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

    // Check source of RPGLE program for defined warnings/errors.
    checkSource();

    // If there are warnings of errors, I will add information to EVFEVENT.
    if #warnings.number > 0 or
       #errors.number > 0;

        open EVFEVENT;

        // - Warnings
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
            // *NODEBUGIO warning
            if #warnings.nodebugio <> 'Y';
                addError(7);
            endif;
            // *INLR warning
            if #warnings.inlr <> 'Y';
                addError(6);
            endif;
        endif;

        // - Errors
        if #errors.number > 0;
            if #errors.dftactgrp <> 'Y';
                addError(4);
            endif;
            if #errors.actgrp <> 'Y';
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

        // If some error was found, then I will send an *ESCAPE msg to stop the compilation.
        if #errors.number > 0;
            snd-msg *escape %msg('RNS9310' : 'QDEVTOOLS/QRPGLEMSG' : #program)
            %target(*caller:2);
        endif;

    endif;

    *inlr = '1';

end-proc;

//
// checkSource procedure.  
// Checks source of the RPGLE program and finds the possible errors/warnings.
//
dcl-proc checkSource;

    dcl-s #startline zoned(5) inz;
    dcl-s #lines zoned(5) inz;
    dcl-s #pos zoned(5) inz;
    dcl-s #pos2 zoned(5) inz;
    dcl-s #list char(50) dim(*auto:30);

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

            // Looks for **FREE.
            if %upper(s_srcdta) = '**FREE';
                #warnings.isfree = 'Y';
                #warnings.number += 1;
                #warnings.freeline = #lines;
            endif;

            // Looks for CTL-OPT.
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
                #list = %split(%upper(s_srcdta):' ()');
                // Looks for DFTACTGRP
                if 'DFTACTGRP' in #list;
                    #errors.dftactgrp = 'Y';
                endif;
                // Looks for ACTGRP
                if 'ACTGRP' in #list;
                    #errors.actgrp = 'Y';
                endif;
                // Looks for NODEBUGIO
                if '*NODEBUGIO' in #list;
                    #warnings.nodebugio = 'Y';
                endif;
            endif;

            // Looks for *INLR.
            if %scan('*INLR':%upper(s_srcdta)) > 0;
                #warnings.inlr = 'Y';
            endif;
        endif;
    enddo;
    if #errors.dftactgrp <> 'Y';
       #errors.number += 1;
    endif;
    if #errors.actgrp <> 'Y';
       #errors.number += 1;
    endif;
    if #warnings.nodebugio <> 'Y';
       #warnings.number += 1;
    endif;
    if #warnings.inlr <> 'Y';
       #warnings.number += 1;
    endif;

    close SOURCE;

end-proc;

//
// addError procedure. 
// Adds error/warning to EVFEVENT 
//
dcl-proc addError;
    dcl-pi *n;
        #number zoned(5) const;
    end-pi;

    chain #number revecode;
    if %found;
        #line.errorcode = cod_errorid;
        #line.detail = cod_lineid + ' ' + cod_text;
        e_evfevent = #line.buffer;
        write revfevent;
    endif;

end-proc;
