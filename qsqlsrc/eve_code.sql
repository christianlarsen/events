create or replace table eve_code (
    code_id  for                id          numeric(5) not null 
                                            generated always as identity 
                                            (start with 1 , increment by 1), 
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
