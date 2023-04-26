/ Unit testing for q similar to junit, cunit etc.       <br/>
/ Tests should be specified in their own file/namespace       <br/>
/ Actual test functions should then be named test* and contain assertions.       <br/>
/ <br/>
/ Tests can either pass/fail/exception. Failure is caused by an assert failing.
/ You have the option of configuring qunit to halt on failed assertions allowing
/ you to step into the code at that point.
/ .
/ @author TimeStored.com
/ @website http://www.timestored.com/kdb-guides/kdb-regression-unit-tests
/ © TimeStored - Free for non-commercial use.
/ License: Attribution-NonCommercial-ShareAlike 2.0 UK: England & Wales (CC BY-NC-SA 2.0 UK) 

/ @TODO mocking projections are broken, add test and fix.

system "d .qunit";

EMPTYAR:`actual`expected`msg!```;
FAIL: "assertionFailed"; / exception thrown on assertion fail

/ Controls where known expected values are loaded from and new results are saved to
expectedPath:hsym `$(getenv[`KDBTESTS],"/qtests/expected");
actualPath:hsym `$(getenv[`KDBTESTS],"/qtests/actual");
currentNamespaceBeingTested:`;
currentTestBeingTested:`;

debug:0b; / If true then do not run tests protected, i.e. break on assertion failures etc.
ignoreAllExceptions:0b; / Useful to generate all actual results. i.e. Set 1b, run all tests, copy actual to expected, Set 0b.

failFlag:0b;
r:1; / holder for result of \ts speed timing in runTests
ar:EMPTYAR; / holder for result of last assertion

mocks:{x!x}enlist (::); / dictionary from mock names to their original value etc.
unsetMocks:`$(); / list of variables that are mocked but were unset beforehand

l:("  ";"   "); / stores log entries to allow generating HTML report if required.
lg:{a:string[.z.t],$[type[x]=98h; "\r\n"; "  "],$[type[x] in 10 -10h; x; .Q.s x],"\r\n"; l::l,enlist a; 1 a; x};

// Assert that the relation between expected and actual value holds
// @param actual An object representing the actual result value
// @param expected An object representing the expected value
// @param msg Description of this test or related message
// @return actual object
assertThat:{ [actual; relation; expected; msg]
    relationPassed:.[relation; (actual; expected); 0b];
    lg $[relationPassed; "passed"; "FAILED"]," -> ",msg;
    if[not relationPassed;
        lg "expected = ",-3!expected;
        lg "actual = ",-3!actual;];
    ar::`actual`expected`msg!(actual;expected;msg);
    doCheck[relationPassed;"assertThatFAIL"];
    actual};

// Make the test fail with given message. Useful for placing in 
// code areas that should never be ran or for marking incomplete test code.
fail:{ [msg] 
    failFlag::1b; 
    lg "FAILED -> ",msg;
    ar::`actual`expected`msg!(`fail;`;msg); 
    'fail};

/ If checkPassed is false, set the failFlag and possibly throw an exception.
doCheck:{ [checkPassed; failMsg] 
    failFlag::failFlag or not checkPassed;
    if[failFlag and not .qunit.ignoreAllExceptions;
        'failMsg];};
            
// Assert that actual and expected value are equal
// @param actual An object representing the actual result value
// @param expected An object representing the expected value
// @param msg Description of this test or related message
// @return actual object
assertEquals:{ [actual; expected; msg]
    a:actual; e:expected; aTh:assertThat; / shortcuts
    ar::`actual`expected`msg!(actual;expected;msg);
    if[a~e; :a];
    if[.Q.qt e;
        doCheck[.Q.qt actual; "assertEquals expected an actual table"];
        doCheck[(asc cols a)~asc cols e; "assertEquals tables have same columns"];
        doCheck[(count a)~count e; "assertEquals tables have same number rows"];
        doCheck[all/[a=e]; "assertEquals tables have same data"];
        :a];
    assertThat[a;~;e;msg]};

// Assert that the expectedFilename in the expectedPath contains a variable
// that is equal to actual.
// @param expectedFilename - Symbol - With filename containing binary kdb data with expected result.
assertKnown:{ [actual; expectedFilename; msg]
    fn:`$$[":"=first p:string expectedFilename; 1 _ p; p];
    .Q.dd[actualPath;currentNamespaceBeingTested,fn] set actual;
    .Q.dd[actualPath;currentNamespaceBeingTested,`$string[fn],".txt"] 0: enlist .Q.s actual;
    assertEquals[actual; getKnown expectedFilename; msg] };
    
assertKnownRun:{ [func; arg]
    cleanName:{
        / cope with very long queries as -3 truncates according to console
        originalc:system "c";
        system "c 2000 2000";
        st:ssr[;"=";"_equals_"] ssr[;">";"_gt_"] -3!x;
        system "c "," " sv string originalc;
        / If st>33 characters add md5 and truncate.
        st:(-6#"" sv string md5 st),"-",44 sublist st;
        st:{@[x;where not lower[x] in .Q.an;:;"_"]} st;
        st:ssr[;"__";"_"] ssr[;"__";"_"] ssr[;"__";"_"] st;
        st};
    testName:string (` vs .qunit.currentTestBeingTested) 2;
    expectedFilename:testName,"_",cleanName (func;arg);
    assertKnown[value (func;arg); hsym `$expectedFilename; "knownRun:",-3!(func;arg)]};

// Get a known binary file.
// @param expectedFilename - Symbol - With filename containing binary kdb data with expected result.
getKnown:{ [expectedFilename]
    fn:`$$[":"=first p:string expectedFilename; 1 _ p; p];
    f:.Q.dd[expectedPath;currentNamespaceBeingTested,fn];
    @[get; f; {$[.qunit.ignoreAllExceptions;`;`$"couldNotFindExpectedFilename ",x]}]};

// Assert that executing a given function causes an error to be thrown
// @param func A function that takes a single argument
// @param arg The argument for the function
// @param msg Description of this test or related message
// @return result of running function.
assertError:{ [func; arg; msg]   
    assertThrows[func; arg; "*"; msg] };

// Assert that executing a given function causes specific exception to be thrown
// @param exceptionLike A value that is used to check the likeness of an exception e.g. "type*"
assertThrows:{ [func; arg; exceptionLike; msg] 
    ar::`actual`expected`msg!(`noException;`ERR;msg);
    doCheck[(type func) within 100 104h; "assertT first arg should be function type within 100 104h. ",msg];
    r:@[{(1b;x y)}[func;]; arg; {(0b; x)}];
    if[not failFlag;  
        doCheck[not r 0; "assertThrows Function never threw exception. ",msg];
        doCheck[r[1] like (),exceptionLike; "exception like format expected: ",exceptionLike]];
    ar::`actual`expected`msg!(r 1;`ERR;msg);
    r 1};
    
// assert that actual is true
// @param msg Description of this test or related message
// @return actual object
assertTrue:{ [actual; msg]  assertThat[actual;=;1b; msg]};

// assert that actual is false
// @param msg Description of this test or related message
// @return actual object
assertFalse:{[actual; msg]  assertThat[actual;=;0b; msg]};


// assert that actual is empty i.e. count is zero.
// @param msg Description of this test or related message
// @return actual object
assertEmpty:{ [actual; msg]  assertThat[count actual;=;0; msg]};

// assert that actual is NOT empty i.e. count is greater than zero.
// @param msg Description of this test or related message
// @return actual object
assertNotEmpty:{ [actual; msg]  assertThat[count actual;>;0; msg]};

/ Run all tests in selected namespaces, return table of pass/fails/timings.
/ @param nsList symbol list of namespaces that contains test e.g. `.mytests`yourtests
/ @return a table containing one row for each test, detailing if it passed/failed.
/ @throws nsNoExist If the namespace you selected does not exist.
runTests:{ [nsList] 
    l::("  ";"   ");
    lg "\r\n"; lg "########## .qunit.runTests `",("`" sv string (),nsList)," ##########";
    / no namespaces specified, find all ending with test
    nsl:$[11h~abs type nsList; nsList; `$".",/:string a where (lower a:key `) like "*test"]; 
    a:raze runNsTests each (),nsl;
	if[0=count a; 'noTestsFound];
    // if no parameters actually used, remove the column
    lg[$[all ()~/:a`parameter; delete parameter from a;a]];};
        
/ find functions with a certain name pattern within the selected namespace
/ @logEmpty If set to true write to log that no funcs found otherwise stay silent
findFuncs:{ [ns; pattern; logEmpty]
        fl:{x where x like y}[system "f ",string ns; pattern];
        if[logEmpty or 0<count fl; lg pattern," found: `","`" sv string fl];
        $[ns~`.; fl; `${"." sv x} each string ns,/:fl]};

/ attempt to run 0-arg function or throw an error
run:{@[value lg x;::;{'lg "setUpError",x}]};        
        

/ Run all tests for a single namespace, return table of pass/fails/timings.
/ @return table of results, or empty list if no tests found
/ @param ns symbol specifying a single namespace to test e.g. `.mytests
runNsTests:{ [ns]
    if[not (ns~`.) or (`$1_string ns) in key `; 'nsNoExist]; // can't find namespace
    currentNamespaceBeingTested::{$["."=first a:string x; `$1 _ a; x]} ns;
    ff:findFuncs[ns;;1b];
    run each findFuncs[ns;"beforeParameters*";0b];
    pFunc:first findFuncs[ns;"parameters*";0b];
    pVals:$[0<count pFunc; @[run;pFunc;()]; ()];
    if[count pVals; lg "parameters = ",-3!pVals];
    idx:0;
    c:();
    do[max 1,count pVals;
        if[count pVals; lg "parameter = ",-3!pVals idx];
        @[ns;`parameter;:;pVals idx];
        run each ff "beforeNamespace*";
        testList: ff "test*";
        runRes: runTest each  testList;
        runRes:update parameter:(count testList)#enlist pVals idx from runRes;
        c,:runRes;
        run each ff "afterNamespace*";
        idx+:1];
    run each findFuncs[ns;"afterParameters*";0b];
    $[count c; `status`name`result`actual`expected`msg`time`mem xcols update namespace:ns,name:testList from c; ()] };
    
/ for fully specified test function in namespace get its config dictionary.
getConf:{ [fn]     
    d:`maxTime`maxMem!(0Wj;0Wj); / default
    conf: @[{{ .[`$".",string x 1;`qunitConfig,x 2] }` vs x}; fn; ``!``];
    $[99h~type conf; d,conf; d]};
    
/ protectively evaluate a single test. 
/ @return dictionary of test success/failure, name, result etc.
runTest:{ [fn]
    lg "#### .qunit.runTest `",string fn;
    currentTestBeingTested::fn;
    // check single arg function
    validTest:$[100h~type vFn:value fn; $[1~count (value vFn) 1; 1b; 0b]; 0b];
    if[not validTest; :(0b;0b;"test should be single arg function")];
    failFlag:: 0b;
    ar::EMPTYAR;
    // run setUp*
    ns:();
    if[2<=sum "."=a:string fn; 
        ns:`$(last ss[a;"."])#a;
        run each findFuncs[ns;"setUp*";0b]];
    // run actual test
/   r:@[{(1b; value[x] y)}[fn;]; ::; {(0b;x)}]; / safer non escaping version.
    r:value "{a:system \"ts .qunit.r:@[{(1b; value[`",string[fn],"] x)}; ::",$[debug;"";"; {(0b;x)}"],"];\"; `ran`result`time`mem!.qunit.r,a}[]";
    if[not r `ran; lg "test threw exception"];
    if[count ns; run each findFuncs[ns;"tearDown*";0b]];
    // cleanup dict format
    r[`status]: $[failFlag; `fail; $[not r `ran; `error; `pass]];
    r,:ar,`maxTime`maxMem#getConf fn; / show last assert on failure
    if[not[failFlag] and any r[`time`mem]>r`maxTime`maxMem;
        r[`status`msg]:(`fail;"exceeded max config time/mem")];
    `ran _ r};    

mock:{ [name; val]
    r:@[{(1b;value x)}; name;00b];
    / if variable has an existing value
    $[(not name in unsetMocks) and first r;
        [if[not name in key mocks; mocks[name]:r 1]]; / store original value 
        unsetMocks,:name];
    / make sure func declared in same ns as any existing function        
    if[100h~type fn:mocks name;
        lg "isFunc";
        ns:string first (value fn) 3;
        lg "ns = ",ns;
        v:string $[ns~"";name;last ` vs name];
        lg "v = ",v;
        runInNs[ns; v,":",string val];
        :name];
    / else
    name set val}; 

/ Run a string of code in a given namespace. 
runInNs:{ [ns; code]
    cd:system "d";
    system "d .",ns;
    value code;
    system "d ",string cd;};
    
/ delete a variable of format `.ns.name whether it's defnined in ns or not
removeVar:{ [name]
    // two cases to cover if defined in ns or not
    @[ {![`.;();0b;enlist x]}; name; `]; 
    @[ {n:` vs x; ![`$".",string n 1;();0b;enlist n 2]}; name; `]; };

/ Reset any variables that were mocked
/ @param names list of variables to be reset or if unspecified, reset them all.
/ @return the list of variables unmocked.
reset:{ [names]
    / if no arg, then remove all variables
    n:$[names~(::); unsetMocks union key 1 _ mocks; (),names];
    / remove those that were unset
    removeVar each n inter unsetMocks;
    unsetMocks::unsetMocks except n;
    / remove cached original values
    k:n inter key mocks;
    k set' mocks k;
    emptyDict:{x!x}enlist (::);
    mocks::emptyDict,k _ 1 _ mocks; / the sentinal causes remove problems
    n };


//########## REPORTING FUNCTIONALITY ############ - Work in Progress

/ Generate an HTML report displaying the results of a test run
/ @param runTestsResult - Table returned from runTests
/ @param path - symbol - specifying location that HTML file is saved to e.g. `:html/qunit.html
generateReport:{ [runTestsResult; path]
    / expand console size to allow full display of data for diffs
    origC:system "c";
    system "c 2000 2000";
    f:hopen @[hdel; path; path];
    f "<html xmlns='http://www.w3.org/1999/xhtml' xml:lang='en' ><head><meta http-equiv='content-type' content='text/html; charset=iso-8859-1' /><title>qUnit Run - TimeStored.com</title><link rel='stylesheet' href='http://www.timestored.com/css/qunit.css' type='text/css' media='screen' /><link rel='shortcut icon' type='image/png' href='http://www.timestored.com/favicon.png' /></head><body><div id='wrap'><div id='page'><div id='header'><h2><a class='qlogo' href='http://www.timestored.com/kdb-guides/kdb-regression-unit-tests?utm_source=qunitrun&utm_medium=app&utm_campaign=qunitrun' target='a'>q<span>Unit</span></a> - <a target='a' href='http://www.timestored.com'>TimeStored.com</a></h2></div><div id='main'>";
    f formatTable update cssClass:status from delete actual,expected,result,msg from runTestsResult;
    testToHtml:{ [f; testDict]
        f "<div class='qtest'><h2>",string[testDict`name],"</h2><p>",testDict[`msg],"</p>";
        f "<textarea class='actual'>",.Q.s[testDict`actual],"</textarea>";
        f "<textarea class='expected'>",.Q.s[testDict`expected],"</textarea></div>";
        };
    testToHtml[f;] each select from runTestsResult where status=`fail;
    f "<h2>Log</h2><textarea class='log'>";
    f each 2 _ .qunit.l;
    f "</textarea>";
    f "<script src='http://www.timestored.com/js/qunit.js'></script></div><div id='footer'> <p>&copy; 2013 <a class='qlogo' href='http://www.timestored.com/kdb-guides/kdb-regression-unit-tests?utm_source=qunitrun&utm_medium=app&utm_campaign=qunitrun' target='a'>q<span>Unit</span></a> | <a target='a' href='http://www.timestored.com'>TimeStored.com</a> | <a target='a' href='http://www.timestored.com/kdb-training?utm_source=qunitrun&utm_medium=app&utm_campaign=qunitrun'>KDB Training</a> | <a target='a' href='http://www.timestored.com/contact?utm_source=qunitrun&utm_medium=app&utm_campaign=qunitrun'>Contact Us</a></p></div></div></div>";
    hclose f;
    system "c "," " sv string origC;
    };

/ Display a kdb table as HTML, using cssClass column for css class in HTML
formatTable:{  [tbl]
    t:() xkey tbl;
    w:{ a:string[x],">"; l:y,"<",a; r:"</",a; l,((r,l) sv z),r};
    header:.h.htc[`tr;]  w[`th;"\t";string (cols t) except `cssClass];
    toTabRow:{
        flattr:{"\t " sv  {.h.htc[`td;] .h.hc $[10h=type a:string x; a; .Q.s1 x]} each x};
        .h.htac[`tr; enlist[`class]!enlist x`cssClass; flattr value `cssClass _ x] };
    content:"\r\n" sv toTabRow each t;
    .h.htc[`table;] (.h.htc[`thead;] header),content}; 
