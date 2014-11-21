// Node.js endpoint for ProjectYaML API

var yaml_bin = __dirname+ "/yaml"; // Set project_yaml.rb path
console.log(yaml_bin);
var execFile = require("child_process").execFile; // create our execFile object
var express = require('express'); // include our express libs
var common = require('./common.js');
var InvalidURIPathError = common.InvalidURIPathError;
var urlDecode = common.urlDecode;
var returnError = common.returnError;
var checkinCount = 0;

app = express.createServer(); // our express server
app.use(express.bodyParser()); // Enable body parsing for POST
// app.use(express.profiler()); // Uncomment for profiling to console
// app.use(express.logger()); // Uncomment for logging to console

// Exception for boot API request
app.get('/yaml/api/boot*',
    function(req, res) {
        try {
            args = getRequestArgs(req);
            if (args.length < 3)
                args.push('default');
            args.push(JSON.stringify(req.query));
            console.log(yaml_bin + getArguments(args));
            execFile(yaml_bin, args, function (err, stdout, stderr) {
                if(err instanceof Error)
                    returnError(res, err);
                else
                    res.send(stdout, 200, {"Content-Type": "text/plain"});
            });
        } catch(e) {
            returnError(res, e);
        }
   });

app.get('/yaml/api/winpeboot*',
    function(req, res) {
        try {
            args = getRequestArgs(req);
            if (args.length < 3)
                args.push('default');
            args.push(JSON.stringify(req.query));
            console.log(yaml_bin + getArguments(args));
            execFile(yaml_bin, args, function (err, stdout, stderr) {
                if(err instanceof Error)
                    returnError(res, err);
                else
                    res.send(stdout, 200, {"Content-Type": "text/plain"});
            });
        } catch(e) {
            returnError(res, e);
        }
   });

app.get('/yaml/api/*',
    function(req, res) {
        console.log("GET " + req.path);
        try {
            args = getRequestArgs(req);
            isCheckin = false;
            if (args.length < 3)
                args.push('default');
            if (command_included(args, "checkin"))
                isCheckin = true;

            if (isCheckin) {
                console.log("Number of waiting mk-checkin processes: [" + checkinCount + "]");
                if (checkinCount < checkinThreshold) {
                    checkinCount++;
                } else {
                    console.log('Ignore mk-checkin Request since Threshold hitted');
                    throw "Ignore MK Checkin";
                }
            }

            args.push(JSON.stringify(req.query));
            console.log(yaml_bin + getArguments(args));
            execFile(yaml_bin, args, function (err, stdout, stderr) {
                if(isCheckin && checkinCount > 0)
                    checkinCount--;

                if(err instanceof Error)
                    returnError(res, err);
                else
                    returnResult(res, stdout);
            });
        } catch(e) {
            if(e !== "Ignore MK Checkin" && isCheckin && checkinCount > 0)
                checkinCount--;

            returnError(res, e);
        }
    });

app.post('/yaml/api/*',
    function(req, res) {
        console.log("POST " + req.path);
        try {
            args = getRequestArgs(req);
            if (!(command_included(args, "add") || command_included(args, "checkin") || command_included(args, "register"))) {
                args.push("add");
            }
            args.push(req.param('json_hash', null));
            //process.stdout.write('\033[2J\033[0;0H');
            console.log(yaml_bin + getArguments(args));
            execFile(yaml_bin, args, function (err, stdout, stderr) {
                if(err instanceof Error)
                    returnError(res, err);
                else
                    returnResult(res, stdout);
            });
        } catch(e) {
            returnError(res, e);
        }
    });

app.put('/yaml/api/*',
    function(req, res) {
        console.log("PUT " + req.path);
        try {
            args = getRequestArgs(req);
            if (!command_included(args, "update")) {
                args.splice(-1, 0, "update");
            }
            args.push(req.param('json_hash', null));
            console.log(yaml_bin + getArguments(args));
            execFile(yaml_bin, args, function (err, stdout, stderr) {
                if(err instanceof Error)
                    returnError(res, err);
                else
                    returnResult(res, stdout);
            });
        } catch(msg) {
            returnError(res, e);
        }
    });

app.delete('/yaml/api/*',
    function(req, res) {
        console.log("DELETE " + req.path);
        try {
            args = getRequestArgs(req);
            if (!command_included(args, "remove")) {
                args.splice(-1, 0, "remove");
            }
            console.log(yaml_bin + getArguments(args));
            execFile(yaml_bin, args, function (err, stdout, stderr) {
                if(err instanceof Error)
                    returnError(res, err);
                else
                    returnResult(res, stdout);
            });
        } catch(msg) {
            returnError(res, e);
        }
    });

// APIs for Cloud Manager
app.get('/yaml/api4cm/snode*',
    function(req, res) {
        console.log("GET " + req.path);
        try {
            args = getRequestArgs(req);
            args.splice(1, 1, "node");
            args.unshift('-c');
            console.log("Parse " + args);
            if (args.length < 4)
                args.push('default');
            else if (args.length == 4)
                args.splice(3, 0, "sn");

            args.push(JSON.stringify(req.query));
            console.log(yaml_bin + getArguments(args));
            execFile(yaml_bin, args, function (err, stdout, stderr) {
                if(err instanceof Error)
                    returnError(res, err);
                else
                    returnSNodeResult(res, stdout);
            });
        } catch(e) {
            returnError(res, e);
        }
    });

app.get('/yaml/api4cm/*',
    function(req, res) {
        console.log("GET " + req.path);
        try {
            args = getRequestArgs(req);
            args.unshift('-c');
            if (args.length < 4)
                args.push('default');

            if (command_included(args, "bmc") && command_included(args, "reboot"))
                args.push(req.param('json_hash', null));
            else
                args.push(JSON.stringify(req.query));
            console.log(yaml_bin + getArguments(args));
            execFile(yaml_bin, args, function (err, stdout, stderr) {
                if(err instanceof Error)
                    returnError(res, err);
                else
                    returnResult4CM(res, stdout);
            });
        } catch(e) {
            returnError(res, e);
        }
    });

app.post('/yaml/api4cm/*',
    function(req, res) {
        console.log("POST " + req.path);
        try {
            args = getRequestArgs(req);
            args.unshift('-c');
            if (!(command_included(args, "add"))) {
                args.push("add");
            }
            args.push(req.param('json_hash', null));
            //process.stdout.write('\033[2J\033[0;0H');
            console.log(yaml_bin + getArguments(args));
            execFile(yaml_bin, args, function (err, stdout, stderr) {
                if(err instanceof Error)
                    returnError(res, err);
                else
                    returnResult4CM(res, stdout);
            });
        } catch(e) {
            returnError(res, e);
        }
    });

app.put('/yaml/api4cm/*',
    function(req, res) {
        console.log("PUT " + req.path);
        try {
            args = getRequestArgs(req);
            args.unshift('-c');
            if (!command_included(args, "update")) {
                args.splice(-1, 0, "update");
            }
            args.push(req.param('json_hash', null));
            console.log(yaml_bin + getArguments(args));
            execFile(yaml_bin, args, function (err, stdout, stderr) {
                if(err instanceof Error)
                    returnError(res, err);
                else
                    returnResult4CM(res, stdout);
            });
        } catch(msg) {
            returnError(res, e);
        }
    });

app.delete('/yaml/api4cm/*',
    function(req, res) {
        console.log("DELETE " + req.path);
        try {
            args = getRequestArgs(req);
            args.unshift('-c');
            if (!command_included(args, "remove")) {
                args.splice(-1, 0, "remove");
            }
            console.log(yaml_bin + getArguments(args));
            execFile(yaml_bin, args, function (err, stdout, stderr) {
                if(err instanceof Error)
                    returnError(res, err);
                else
                    returnResult4CM(res, stdout);
            });
        } catch(msg) {
            returnError(res, e);
        }
    });


app.get('/*',
    function(req, res) {
        switch(req.path)
        {
            case "/yaml":
                res.send('Bad Request(No module selected)', 404);
                break;
            case "/yaml/api":
                res.send('Bad Request(No slice selected)', 404);
                break;
            default:
                res.send('Bad Request', 404);
        }
    });

/**
 * Assembles an array of argument, starting with the string '-w' and then
 * followed by URI decoded path elements from the request path. The first
 * two path elements are skipped.
 *
 * @param req The Express Request object
 * @returns An array of arguments
 * @throws An 'Illegal path component' if some path element is considered unsafe
 */
function getRequestArgs(req) {
    args = req.path.split("/");
    args.splice(0,3);
    if(args.length > 0) {
        if(args[args.length-1] == '')
            // Path ended with slash. Just skip this one
            args.pop();

        for(var i = 0; i < args.length; ++i)
            args[i] = urlDecode(args[i]);
    }
    args.unshift('-w');
    return args;
}

function returnResult(res, json_string) {
    var return_obj;
    var http_err_code;
    try
    {
        return_obj = JSON.parse(json_string);
        http_err_code = return_obj['http_err_code'];
        res.writeHead(http_err_code, {'Content-Type': 'application/json'});
        res.end(json_string);
    }
    catch(err)
    {
    	// Apparently not JSON and should be sent as plain text.
    	// TODO: This approach is bad. We should know what to do with
    	// the json_string, not guess. What if the response can be parsed but
    	// still isn't JSON?
        res.send(json_string, 200, {'Content-Type': 'text/plain'});
    }
}

function returnSNodeResult(res, json_string) {
    var return_obj;
    var http_err_code;
    var response;
    var command;
    try
    {
        return_obj = JSON.parse(json_string);
        http_err_code = return_obj['http_err_code'];
        response = return_obj['response'];
        result = return_obj['result'];
        command = return_obj['command'];
        res.writeHead(http_err_code, {'Content-Type': 'application/json'});

        if (response && response.length == 1 && command != 'get_node_by_sn') {
          var ret = response.shift();
          res.end(JSON.stringify(new Array(ret['serial_number'])));
        } else if (response && response.length > 1) {
          var array_uuids = new Array();
          len = response.length;
          while (len--) {
            array_uuids.push(response[len]['serial_number']);
          }
          res.end(JSON.stringify(array_uuids))
        } else {
          res.end(JSON.stringify(response || result));
        }
    }
    catch(err)
    {
    	// Apparently not JSON and should be sent as plain text.
    	// TODO: This approach is bad. We should know what to do with
    	// the json_string, not guess. What if the response can be parsed but
    	// still isn't JSON?
        res.send(json_string, 200, {'Content-Type': 'text/plain'});
    }
}

function returnResult4CM(res, json_string) {
    var return_obj;
    var http_err_code;
    var response;
    var command;
    try
    {
        return_obj = JSON.parse(json_string);
        http_err_code = return_obj['http_err_code'];
        response = return_obj['response'];
        result = return_obj['result'];
        command = return_obj['command'];
        res.writeHead(http_err_code, {'Content-Type': 'application/json'});

        if (command.indexOf('_query_all') != -1 || command.indexOf('query_with_filter') != -1) {
          if (response.length == 1) {
            var ret = response.shift();
            if (command == 'tasks_query_all') {
              res.end(JSON.stringify(new Array(ret['task_uuid'])));
            } else {
              res.end(JSON.stringify(new Array(ret['uuid'])));
            }
          } else if (response.length > 1) {
            var array_uuids = new Array();
            len = response.length;
            while (len--) {
              array_uuids.push(response[len]['uuid']);
            }
            res.end(JSON.stringify(array_uuids))
          } else {
            res.end(JSON.stringify(response || result));
          }
        } else if (command == 'add_task' || command == 'update_task' || command == 'remove_task_by_uuid') {
          var hsh = new Object();
          if (response && response.length == 1) {
            var ret = response.shift();
            hsh['uuid'] = ret['task_uuid'];
          } else {
            hsh['uuid'] = "";
          }
          hsh['message'] = result;
          res.end(JSON.stringify(new Array(hsh)));
        } else {
          res.end(JSON.stringify(response || result));
        }
    }
    catch(err)
    {
    	// Apparently not JSON and should be sent as plain text.
    	// TODO: This approach is bad. We should know what to do with
    	// the json_string, not guess. What if the response can be parsed but
    	// still isn't JSON?
        res.send(json_string, 200, {'Content-Type': 'text/plain'});
    }
}

function getArguments(args) {
    var arg_string = " ";
    for (x = 0; x < args.length; x++) {
        arg_string = arg_string + "'" + args[x] + "' "
    }
    return arg_string;
}

function getConfig() {
    execFile(yaml_bin, ['-j', 'config', 'read'], function (err, stdout, stderr) {
        console.log(stdout);
        startServer(stdout);
    });
}

function command_included(arr, obj) {
    return arr.indexOf(obj) >= 0;
}

// TODO Add catch for if project_yaml.js is already running on port
// Start our server if we can get a valid config
function startServer(json_config) {
    config = JSON.parse(json_config);
    checkinThreshold = config['@nodejs_mk_checkin_threshold'];
    if (!isFinite(checkinThreshold) || checkinThreshold <= 0)
        checkinThreshold = 100;
    console.log('Config Threshold of waiting MK checkin requests to %d', checkinThreshold);

    if (config['@api_port'] != null) {
        app.listen(config['@api_port']);
        console.log('ProjectYaML API Web Server started and listening on:%s', config['@api_port']);
    } else {
        console.log("There is a problem with your ProjectYaML configuration. Cannot load config.");
    }
}


getConfig();
