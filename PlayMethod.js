
var radio   = require('TRRadio').singleton();
var radioId = radio.radioId();


var urlString =
require('NSMutableString').stringWithString("http://hichannel.hinet.net/radio/schannel.do?id=");
urlString.appendString(radio.radioId());


var URL = require('NSURL').URLWithString(urlString);
var request = require('NSMutableURLRequest').requestWithURL(URL);
request.setTimeoutInterval(30.0);
request.setValue_forHTTPHeaderField(URL.absoluteString(), 'Referer');
request.setValue_forHTTPHeaderField('xUite9602@hIchaNnel', 'XuiteAuth');

var defaultConfig =
    require('NSURLSessionConfiguration').defaultSessionConfiguration();

var queue = require('NSOperationQueue').mainQueue();

var defaultSession =
    require('NSURLSession').sessionWithConfiguration_delegate_delegateQueue(defaultConfig, null, queue);

var dataTask =
    defaultSession.dataTaskWithRequest_completionHandler(request, block('NSData*,NSURLResponse*,NSError*', function(data,response, error)
    {
		var JSON = require('NSJSONSerialization').JSONObjectWithData_options_error(data, 0, null);
		var playRadio = JSON.valueForKey('playRadio');
                    
		if(!JSON.isKindOfClass(require('NSDictionary').class()))
		{      
			radio.setRadioStatus(4);

			return;
		}

		if(!playRadio)
		{
			radio.setRadioStatus(4);

			return;
		}

		var URL = require('NSURL').URLWithString(playRadio);
		var item = require('AVPlayerItem').playerItemWithURL(URL);

		dispatch_async_main(function(){
			radio.replaceCurrentItemWithPlayerItem(item);
		});
     }));

dataTask.resume();

