## Events ##

This program can be used as a compiler for RPG programs (not in stream files). 
It can add a "compilation error", even if the program is ok.

To use it, just create in VSCode, a new "Action", in the "member" section.
You should put:

Action name: For example Create Bound RPG Program with Events

Command to run:
CALL CLEVENTS PARM(&OPENLIB &OPENMBR *EVENTF)



