**free
ctl-opt main(main);

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
dcl-s #error ind;
dcl-ds *n;
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
    detail char(25) inz(' 30 001 This is TEST!!');
    buffer char(400) pos(1);
end-ds;
dcl-ds #data dim(*auto:1000) qualified;
    #evfevent char(400);
end-ds;

dcl-proc main;

    dcl-pi *n;
        #library char(10) const;
        #program char(10) const;
        #error ind;
    end-pi;

    #evfevent = %trim(#library) + '/EVFEVENT';
    #mbr = #program;

    %elem(#data) = 0;
    #z = 0;
    #add = 'N';
    open EVFEVENT;
    // Busco FILEEND e inserto delante lo que quiero
    // Cargo la estructura con los datos que hay en EVFEVENT
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

    open EVFEVENT;
    e_evfevent = buffer;
    write revfevent;
    for #z = 1 to %elem(#data);
        //if %subst(#data(#z).#evfevent:49:7) = 'CPC5D07';
        //   iter;
        //endif;
        e_evfevent = #data(#z).#evfevent;
        write revfevent;
    endfor;

    close EVFEVENT;

    #error = '1';

    if #error = '1';
    // Sending message "RNS9310" (compilation error)
    // (I need VSCode read that error)
    snd-msg *escape %msg('RNS9310' : 'QDEVTOOLS/QRPGLEMSG' : #program) %target(*caller:2);
    endif;
end-proc;