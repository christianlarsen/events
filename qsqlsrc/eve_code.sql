create or replace table eve_code (
    code_id  for                id          numeric(5) not null, 
    error_id for                errorid     char(2),
    line_id for                 lineid      char(3),
    error_text for              text        char(50),

    primary key(code_id)
)
rcdfmt revecode;

label on table eve_code is 'EVENTS Error codes';

label on column eve_code (
    id          is 'Code ID',
    errorid     is 'Error ID',
    lineid      is 'Line ID',
    text        is 'Error Text'
);

insert into eve_code values (1 , '00', '001', 'This is a FREE source');
insert into eve_code values (2 , '00', '001', 'This is NOT a FREE source');
insert into eve_code values (3 , '00', '001', 'CTL-OPT missing.');
insert into eve_code values (4 , '30', '001', 'DFTACTGRP(*NO) missing.');
insert into eve_code values (5 , '30', '001', 'ACTGRP missing.');
