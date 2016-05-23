// HbbTV objects
var appManager = null; //document.getElementById("appManager");
var videoBroadcast = null; // document.getElementById("videoBroadcast");
var app = null;

// default stream event values
var steEventName   = "Event1";
var steObject = "test.event";
var steListenerSet = false;
var totalEventCount = 0;
var steTimer = null;

// default log values
var logURL = "http://url_to_log_server";
var info = null; //document.getElementById("info");

function logToServer(msg){
        var request = new XMLHttpRequest();  
        request.open('GET', logURL + "?" + msg, true);
        request.send();
};

function log(msg) {
	info.innerHTML = info.innerHTML + "<br/>" + msg;
};  

function init() {
	setKeyEventListener();
	initHbbTVApp();
	initSTE();
};

function initSTE(){
	videoBroadcast    = document.getElementById("videoBroadcast");
	if (!videoBroadcast.bindToCurrentChannel) {
		log("error_bindToCurrentChannel_doesnotexists");
		return;
	}

	videoBroadcast.bindToCurrentChannel();	
	
	if (videoBroadcast.playState == 2) {
		log("success_videoBroadcastPlayState");
		setStreamEventListener();
	} else {
		videoBroadcast.onPlayStateChange = function(state, error) {
			if (videoBroadcast.playState == 2) {
				log("success_videoBroadcastReadyOnPlayStateChange");
				setStreamEventListener();
			}
		};
		steTimer = window.setTimeout(function() {
			killSteTimer();	
			log("waited_steTimer");
			setStreamEventListener();}, 5000);
	}

};

function initHbbTVApp(){
	appManager    = document.getElementById("appManager");
	if (!appManager.getOwnerApplication) {
		log("error_getOwnerApplication_doesnotexists");
		return;
	}
	
	try {
        app = appManager.getOwnerApplication(document);
	} catch (e) {
		log("error_cannot_getOwnerApplication");
	}
	
	try {
		app.show();
	} catch (e2) {
		log("error_cannot_appShow");
	}

	app.privateData.keyset.setValue(0x1);

	try {
		app.activate();
	} catch (e2) {
		log("error_cannot_appShow");
	}
};

function setKeyEventListener() {
	info = document.getElementById("info");
    	document.addEventListener("keydown", function(e) {
        	if (handleKeyCode(e.keyCode)) {
            		e.preventDefault();
       	 	}
    	}, false);
};

function handleKeyCode(keyCode) {
    	if (keyCode === VK_RED) {
       		log("success_red_button_pressed");
        	return true;
    	}
    	return false;
};

function setStreamEventListener() {
	try {		
		videoBroadcast.addStreamEventListener(steObject, steEventName, handleSTE);
		steListenerSet = true;
	} catch (e) {
		log("error_cannot_ addStreamEventListener=");
	}
	return steListenerSet;
};

function killSteTimer(){
	if (steTimer) {
		window.clearTimeout(steTimer); 
		steTimer = null;
	}

};

function handleSTE(ste) {
	try {
		totalEventCount++;
		log("success_streamEventRecieved [ name=" + ste.name + ", text="+ ste.text + ", status=" + ste.status + ", totalevent="  + totalEventCount);
	} catch (e) {
		log("error_cannot_parseSteEvent");
	}
};
