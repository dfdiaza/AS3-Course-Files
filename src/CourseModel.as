﻿package src{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import src.AssetClasses.TocPage;
	import src.AssetClasses.TocTopic;
	import src.SettingsModel;
	import src.classes.InfoPanel;
	import src.classes.LoadingPercentages;
	import src.com.AlertButton;
	import src.com.Alerts;
	import src.pages.quiz.Quiz;
	import src.pages.quiz.QuizObjects;
		public class CourseModel extends Model	{		//Variables for storing XML Data.		public var topics:XMLList;		public var topicAndPages:XMLList;//The index can be built from this.		public var activePages:XMLList;		public var quizzes:XMLList;		public var letters:XMLList;		public var currentPage:XML;		public var currentTopic:XML;		public var nextSibOfTopic:XML;		public var currentTitle:String;		public var currentFile:String;		public var mainTitle:String;		public var scoData:XML;		public var quizData:XML;		public var glossaryData:XML;		public var navablePgs:XMLList;				//Keeps list of pages for the course.		public var quizPgs:XMLList;					//Keeps list of pages for a quiz		public var navableQuizPgs:XMLList;			//Navable page list used when inside a quiz.		public var pageAttributes:PageAttributes;	//stores all page attributres from current page in XML file.		public var courseAttributes:CourseAttributes;//Stores all course attributes from XML file (sco tag)		public var quizObjs:Quiz;					//Stores all quizObjects that have been created.		public var inQuizNav:Boolean	=	false;	//Set to true if the current navigation is inside a quiz object.						private var modelCnt:int;		private var _coursePreloader:MovieClip;		private var _feedbackPanel:InfoPanel;		private var _mainPlayer:MovieClip; //Stores reference to the main player file.		private var _previousIndex:int;				//Stores the previous page index in case we need to revert back to it.		private var _randomQuestionCnt:int = 0;		//Counter for question if it is a test and randomized.				//Course Status		private var _audioVolume:Number;		private var _audioStatus:String;				//Either on OR off		private var _indexState:String;					//Either read OR index		private var _playState:String;					//Either play or pause -- state of play button and media.		private var _mediaControlVisibility:Boolean; 	//Either true or false		private var _glossaryState:String = "hidden";	//Either visible or hidden;		private var _indexVisibleState:String = "hidden";	//Either visible or hidden;		private var _lms:LmsCom; 						//SCORM and AICC APIs		private var _apiFound:Boolean = true;		private var _percentObj:LoadingPercentages; 	//Simply for determining loading percentage.		private var _perc:Number;		private var _curTopic_mc:MovieClip; 			//The topic movie clip inside TOC that is currently active		private var _curPage_mc:MovieClip;				//The page movie clip inside TOC that is currently selected.		private var _toc_mc:MovieClip;					//A reference to the toc movie clip that is loaded for the index.		private var _restrictNavAlert:Alerts			//Alert object for restricted navigation.		private var _pageIsComplete:Boolean;			//Keep track of whether or not current page is marked complete.		private var _autoNavTimer:Timer;				//Timer for auto navigation if required.		private var _connectString:String;				//Keeps track of current connection string for loading AS2 movies.		private var _oldConnectString:String;			//Keeps track of previous connection string for loading AS2 movies.		private var _connectStringAS2:String;			//connection string used by AS2 loader		private var _quizPageIndex:int;					//index of current quiz page. Used if not doing Random		private var _curQuizObject:QuizObjects;			//Stores reference to the current quiz object		private var _totQuestions:uint;					//Stores total questions if there is a subset entered.		private var _backwardNavigation:Boolean = false;//Set to true if navigating to previous page.		private var _backwardNavAlert:Alerts;			//Alert if they navigate backwards when not allowed.		private var _totQuestionCnt:uint = 0;			//Stores total number of questions for all quiz so total can be added to total pages if needed.				public static const AUDIO_CHANGED:String = "audioChanged";		public static const INDEX_CHANGED:String = "indexChanged";		public static const MEDIA_CHANGED:String = "mediaChanged";		public static const MEDIACONTROL_STATE:String = "mediaControlState";		public static const INDEX_VISIBILITYCHANGED:String = "indexVisibilityChanged";		public static const PAGE_COMPLETE:String = "pageComplete";						public function CourseModel(cp:MovieClip,mp:MovieClip)		{			modelCnt = 1;			_coursePreloader = cp;			_mainPlayer = mp;			_audioVolume = .8;			_audioStatus = "on";			_indexState = "index";			_playState = "pause";			pageAttributes = new PageAttributes();			courseAttributes = new CourseAttributes();			quizObjs = new Quiz(this);			_percentObj = new LoadingPercentages();			_perc = _percentObj.courseModelPerc;						// initialize the alert window			_restrictNavAlert = new Alerts();			_backwardNavAlert = new Alerts();						// add listeners			_restrictNavAlert.addEventListener(Alerts.RIGHT_BUTTON_CLICK, onRestrictConfirm);			_backwardNavAlert.addEventListener(Alerts.RIGHT_BUTTON_CLICK,onBackNavConfirm);						// add the alert window to the display list			if (_coursePreloader != null) //Check to see if the course is playing inside of the course.swf file.			{				_coursePreloader.parent.addChild(_restrictNavAlert);				_coursePreloader.parent.addChild(_backwardNavAlert);			} else {				_mainPlayer.addChild(_restrictNavAlert);				_mainPlayer.addChild(_backwardNavAlert);			}		}				public function changePage(ind:int):void		{				_feedbackPanel.updatePanel("changePage of CourseModel: inQuizNav= " + inQuizNav + " -ind= " + ind + " -currentIndex= " + currentIndex);			//trace("changePage of CourseModel: inQuizNav= " + inQuizNav + " -ind= " + ind + " -currentIndex= " + currentIndex);			if (ind < 0)			{				_backwardNavigation = true;			} else {				_backwardNavigation = false;			}			//trace("Backward: " + _backwardNavigation);			//trace("Quiz Page Index: " + _quizPageIndex);			if (!inQuizNav)			{				var index:int = currentIndex + ind;				changeNormalPage(index)			} else {				//trace("DEAL with ......... Quiz Navigation.");				//trace("QUESTions: " + _curQuizObject.numQuestions);					//trace("BACK RESTRICTION: " + _curQuizObject.restrictBackwardNav);				if (_curQuizObject.restrictBackwardNav && _backwardNavigation && _quizPageIndex != 0 && _curQuizObject.currentQuestionNum > 1)				{					//Alert USer that backward navigation while in the quiz is not permitted in this course.					//Display Alert					_backwardNavAlert.headerText = "Navigation Restricted";					_backwardNavAlert.alertText = "Returning to a previous question is not allowed.";					_backwardNavAlert.rightButtonText = "OK";										_backwardNavAlert.showAlert();				} else {					if (_quizPageIndex == 0 && ind < 0)					{						//Return to regular navigation						inQuizNav = false;						_curQuizObject = null;						changePage(ind);					} else if ((_quizPageIndex+1) >= _curQuizObject.numPages) {						//Return to regular navigation						inQuizNav = false;												_curQuizObject.quizIsComplete = true;						changePage(ind);						_curQuizObject = null;					} else {						_quizPageIndex = _quizPageIndex + ind;						_curQuizObject.currentQuestionNum = _quizPageIndex;						changeQuizPage();					}				}			}		}				public function changeNormalPage(index:int):void		{			trace("CALL TO CHANGE THE PAGE MADE TO changePage in CourseModel-INDEX: " + index);			if (inQuizNav) inQuizNav = false; //If accessed from TOC make sure to change the quiz nav back.			_pageIsComplete = false;			_previousIndex = currentIndex;			currentIndex = index;			if (controlCurrentIndex())			{				updateData();			}			//Moved the dispatching of event to MainModel.			//Bookmark the page			var success:Boolean = _lms.apiSetBookmark(currentIndex);			if (!success)			{				trace("BOOKMARKING OF PAGE WAS NOT SUCCESSFUL.");				_feedbackPanel.updatePanel("BOOKMARKING OF PAGE WAS NOT SUCCESSFUL. Index: " + currentIndex);			}					}				private function changeQuizPage():void		{			//trace("INDEX: " + _quizPageIndex);			//SET ALL VARIABLES for the CURRENT PAGE			currentPage = navableQuizPgs[_quizPageIndex];			//trace("currentPage: " + navablePgs[currentIndex]);			currentTopic = currentPage.parent();						updatePageData();						trace("CALL TO CHANGE THE PAGE MADE TO changeQuizPage");						trace("Event from CourseModel: MODEL_CHANGE -- in changeQuizPage");			dispatchEvent(new Event(Model.MODEL_CHANGE));					}				public function checkCompletedTopic():void		{			if (curTopicMC != null && !TocTopic(curTopicMC).completed)			{				var pgArray:Array = TocTopic(curTopicMC).childPages;				//trace("Array: " + pgArray.toString());				var isComplete:Boolean = true;				for (var k:int = 0; k < pgArray.length; k++)				{					var pgObj:DisplayObject = tocMC.getChildByName(pgArray[k]);					//trace("visited: " + TocPage(pgObj).visited);					if (TocPage(pgObj).visited == "0")					{						isComplete = false;						break;					}				}				//trace("checking completed topic" + isComplete);				TocTopic(curTopicMC).completed = isComplete;			}		}				private function controlCurrentIndex():Boolean		{			//trace("i: " + currentIndex + " - " + totalItems)			if(currentIndex >= totalItems)			{				currentIndex = totalItems - 1;				return false;			}			else if(currentIndex < 0)			{				currentIndex = 0;				return false;			} else {//Check to make sure the page is selectable. If not display message.				try {					var pageName:String = navablePgs[currentIndex].@pageName;					var pageMC:DisplayObject = _toc_mc.getChildByName(pageName);					var selectable:Boolean = (TocPage(pageMC).selectValue == "1");					if (!selectable)					{						currentIndex = _previousIndex;						//Display Alert						_restrictNavAlert.headerText = "Pages Not Completed";						_restrictNavAlert.alertText = "You must complete all pages in the current topic before you can move on.";						_restrictNavAlert.rightButtonText = "OK";												// show the alert window when you need it						_restrictNavAlert.showAlert();						return false;					}					return true;				} catch (error:Error) {					trace("The course was bookmarked. Therefore no check for restricted Nav was made.");					_feedbackPanel.updatePanel("Because of Bookmarking no restricted navigation check was made.");					return true;				}				return true;			}		}				override protected function updateData():void		{			//SET ALL VARIABLES for the CURRENT PAGE			currentPage = navablePgs[currentIndex];			//trace("currentPage: " + navablePgs[currentIndex]);			currentTopic = currentPage.parent();									//Gather next topic sibling. If statement is for pages at the top level. They won't have a parent that is a topic.			//trace(":::" + XML(navablePgs[currentIndex+1]).toXMLString());			var sibCnt:int = currentIndex+1;			if (navablePgs[sibCnt] != undefined && navablePgs[sibCnt] != null)			{				var nextSib:XML = navablePgs[sibCnt];				while(nextSib.@isTocEntry.toString().toLowerCase() != "true" && sibCnt+1 < navablePgs.length())				{					sibCnt++;					nextSib = navablePgs[sibCnt];				}								if (nextSib.@isTocEntry.toString().toLowerCase() != "false")				{					nextSibOfTopic = nextSib;				} else {					nextSibOfTopic = null;				}			} else {				nextSibOfTopic = null;			}						updatePageData();						//See if it is a quiz			if (currentPage.localName() == "quiz")			{				inQuizNav = true;				//trace("ID......................." + currentPage.@quizid);				var qObj:QuizObjects = quizObjs.getQuizObject(currentPage.@quizid);				_curQuizObject = qObj;				//Create Global Feedback				qObj.getGlobalFeedback(currentPage);				//Establish settings for quiz				qObj.getQuizSettings(currentPage);				//qObj.questions = quizPgs;				navableQuizPgs = qObj.questions;				//trace("*********" + navableQuizPgs[0]);				_quizPageIndex = 0;				changeQuizPage();			} else {				trace("Event from CourseModel: MODEL_CHANGE");				dispatchEvent(new Event(Model.MODEL_CHANGE));			}		}				override protected function dataLoaded(event:Event):void		{			scoData = new XML(loader.data); 			courseAttributes.updateCourseAttributes(scoData);			topics = scoData.*;			//trace(topics);			topicAndPages = topics.*;			parsePageData(topicAndPages);			//trace("TOPIC AND PAGES: " + topicAndPages);			//trace(topicAndPages.length());			mainTitle = courseAttributes.title;			//trace(mainTitle);			loader.removeEventListener(Event.COMPLETE, dataLoaded);			loader.removeEventListener(ProgressEvent.PROGRESS, dataLoading);						//Connect to LMS communication and SCORM state of course			_lms = new LmsCom(_coursePreloader,this);			_lms.addEventListener(LmsCom.LMS_DATA_LOADED,lmsDataLoaded);			_lms.addEventListener(LmsCom.NO_API_FOUND,noApiFound);			_lms.beginLoading();		}				private function updatePageData():void		//Called from two locations updateData and quiz page navigation. 		{			//trace(":NEXT:" + nextSibOfTopic.toXMLString());			pageAttributes.updatePageAttributes(currentPage);			//trace("CURRENT PAGE XML: " + currentPage);			//currentTitle = currentPage.@title;			currentTitle = pageAttributes.title;			//currentFile = currentPage.@file;			currentFile = pageAttributes.file;			//trace("currentFile in MainModel: " + currentFile);			//totalItems = pages.length();						//Set the pageName for Unison.			_mainPlayer.cc_pageName = currentFile + " - " + currentTitle;		}				private function lmsDataLoaded(e:Event):void		{			trace("******LMS DATA IS LOADED*******");			dispatchEvent(new Event(Model.MODEL_LOADED));		}				private function noApiFound(e:Event):void		{			_apiFound = false;		}				override protected function dataLoading(e:ProgressEvent):void		{			var perc:Number = e.bytesLoaded/e.bytesTotal;			var newPerc:Number;			var prevPerc:Number = _percentObj.previousPercent;			newPerc = perc*(_perc - prevPerc) + prevPerc;			try {			    _coursePreloader.percent_txt.text = Math.ceil(newPerc*100).toString() + "%";				_coursePreloader.status_txt.text = "Loading XML Files...";				_coursePreloader.bar_mc.scaleX = newPerc;			} catch (error:Error) {			     trace("The player file is not running inside the course file: ");			}		}				private function parsePageData(tp:XMLList):void		{			navablePgs = new XMLList();			for each (var item in tp) {			    //trace("I: " + item.localName());			    if (item.localName().toLowerCase() == "page" && item.@nonNavPage.toString().toLowerCase() != "true")			    {			    	navablePgs[navablePgs.length()] = item;					if (item.@quizid.length() > 0)					{						//trace("Has QUIZ ID" + item.@quizid);						createQuizObj(item.@quizid);					}			    } else if (item.localName().toLowerCase() == "topic" && item.@showTopicPages.toString().toLowerCase() != "false") {			    	var t:XML = item;			    	checkTopic(t);			    } else if (item.localName().toLowerCase() == "quiz") {					var q:XML = item;					parseQuiz(q);					//Reset array so it is empty					if (quizPgs.length() > 0)					{						quizPgs = new XMLList();						//trace("L: " + quizPgs.length());					}				}							}			totalItems = navablePgs.length();					if (courseAttributes.includeQuestionCnt)			{				//Include quiz count into the totalItems				totalItems += _totQuestionCnt;			}			trace("XML PARSED--TOTAL NUMBER NAVIGABLE PAGES: " + totalItems);			//trace("VALID: " + navablePgs);		}				private function checkTopic(t:XML,fr:Boolean = false):void //fr is true if this is called from parseQuiz		{			for each (var it in t.elements()) {			    //trace("I: " + item.localName());			    if (it.localName().toLowerCase() == "page" && it.@nonNavPage.toString().toLowerCase() != "true")			    {			    	if (fr)					{						quizPgs[quizPgs.length()] = it;					} else {						navablePgs[navablePgs.length()] = it;					}										if (it.@quizid.length() > 0)					{						//trace("Topic Has QUIZ ID" + it.@quizid);						createQuizObj(it.@quizid);					}			    } else if (it.localName().toLowerCase() == "topic" && it.@showTopicPages.toString().toLowerCase() != "false") {			    	var tp:XML = it;			    	checkTopic(tp);			    } else if (it.localName().toLowerCase() == "quiz") {					var q:XML = it;					parseQuiz(q);					//Reset array so it is empty					if (quizPgs.length() > 0)					{						quizPgs = new XMLList();						//trace("L: " + quizPgs.length());					}				}			}			//trace("***********" + navablePgs[17]);		}				private function parseQuiz(q:XML):void		{			quizPgs = new XMLList();			//Create the quiz object if not already created			createQuizObj(q.@quizid);			var questionCnt:uint = 0;			//Get Total questions in case it is a subset of all of them.			if (q.@numquestions.length() > 0)				_totQuestions = Number(q.@numquestions);			else				_totQuestions = 0;			//trace(q);			for each (var it in q.elements()) {				//trace("I: " + item.localName());				if (it.localName().toLowerCase() == "page" && it.@nonNavPage.toLowerCase() == "false")				{					//navablePgs[navablePgs.length()] = it;										if (q.@quizmode == "test" && q.@randomize == "true")					{						quizPgs[quizPgs.length()] = it;						if (it.@pType.toLowerCase().indexOf("question") > -1) 						{							//trace("T: " + it.@title + " - " + questionCnt);							questionCnt++;						}					} else {						if (it.@pType.toLowerCase().indexOf("question") > -1) 						{							//trace("T: " + it.@title + " - " + questionCnt);							if (questionCnt < _totQuestions)							{								quizPgs[quizPgs.length()] = it;								questionCnt++;							}						} else {							quizPgs[quizPgs.length()] = it;						}					}				} 				/* Currently we don't allow a topic inside a quiz, so this is commented out.								else if (it.localName().toLowerCase() == "topic" && it.@showTopicPages.toLowerCase() == "true") {					var tp:XML = it;					checkTopic(tp,true);				}*/			}			//Randomize XMLList if needed.			if (q.@quizmode == "test" && q.@randomize == "true")			{				quizPgs = randomizeXMLList(quizPgs);			}						//trace("Total Question Count: " + questionCnt);			//Add XMLList of questions to quiz object:			var qObj:QuizObjects = quizObjs.getQuizObject(q.@quizid);			qObj.questions = quizPgs;			if (q.@quizmode == "test" && q.@randomize == "true")			{				qObj.numOfQuestions = _randomQuestionCnt;			} else {				qObj.numOfQuestions = questionCnt;			}						//Add questions for final page count			_totQuestionCnt += qObj.numOfQuestions;			//Add quiz to navigable pages.			//trace(navablePgs.length());			navablePgs[navablePgs.length()] = q;//new XML('<quiz quizid="' + q.@quizid + '" title="' + q.title + '"></quiz>');						//trace("***********" + navablePgs[17]);		}				private function randomizeXMLList(list:XMLList):XMLList		{			//Create an array of numbers for each element in the XMLList. Randomize that array. Use the numers in that array to create a new XML List.			var numArray:Array = new Array();			var pgArray:Array = new Array();						for (var j:int = 0;j < list.length(); j++)			{				if (list[j].@pType.toLowerCase().indexOf("question") > -1) 					numArray[j] = j;				else					pgArray[pgArray.length] = j; //Use this array to position non questions in the correct place.			}						// create a comparison function that will be passed			// to the Array.sort() method			function randomSort(objA:Object, objB:Object):int {				return Math.round(Math.random() * 2) - 1			}						// randomize the Array!			numArray.sort(randomSort);						//Rebuild XMLList			var newList:XMLList = new XMLList();			var whileCnt:uint = 0;			var listArrayCnt:uint = 0;			var numArrayCnt:uint = 0;			var pgArrayStr:String = "," + pgArray.toString() + ",";			var testArray:Array = new Array();			while (whileCnt < list.length())			{				if (pgArrayStr.indexOf("," + whileCnt + ",") > -1)				{					newList[listArrayCnt] = list[whileCnt];					testArray[listArrayCnt] = whileCnt;					listArrayCnt++;				} else {					if (numArrayCnt < _totQuestions)					{						newList[listArrayCnt] = list[numArray[numArrayCnt]];						testArray[listArrayCnt] = numArray[numArrayCnt];						numArrayCnt++;						listArrayCnt++;						_randomQuestionCnt++;					}				}				whileCnt++;			}						//trace(numArray.toString());			//trace(pgArray.toString());			//trace(testArray.toString());			//trace(newList);			return newList;		}				private function createQuizObj(id:String):void		{			//Create a quiz object to track quiz data if not already created.			if (!quizObjs.isQuizCreated(id))			{				quizObjs.addQuizObject(id)				trace("Create a quiz object with this ID:: " + id);				_feedbackPanel.updatePanel("Create a quiz object with this ID:: " + id);			}		}				private function onRestrictConfirm(e:Event):void		{			//Do nothing		}				private function onBackNavConfirm(e:Event):void		{			//Do nothing		}				private function autoNavToNextPage(e:TimerEvent):void		{			//trace("CALLED: " + _autoNavTimer.currentCount);			if (_autoNavTimer.currentCount >= SettingsModel(_mainPlayer.settingsModel).settings.autoNavLatency) //autoNavLatency is the number of seconds to wait between pages.			{				_autoNavTimer.stop();				if (currentIndex < totalItems-1)				{					changePage(1);				} else {					_autoNavTimer.removeEventListener(TimerEvent.TIMER,autoNavToNextPage);				}			}		}				public function markPageComplete(cmdSent:Boolean = false)//cmdSent is true if the command was sent from the loaded SWF.		{			//Notify Views that the page is now complete.			trace("marking complete");			if (courseAttributes.pageComplete)			{				if (!_pageIsComplete)				{					if (cmdSent)					{						_pageIsComplete = true;						dispatchEvent(new Event(CourseModel.PAGE_COMPLETE));					} else if (pageAttributes.pType.toLowerCase().indexOf("default") > -1)					{						if (pageAttributes.sendPageComplete) 						{							_pageIsComplete = true;							dispatchEvent(new Event(CourseModel.PAGE_COMPLETE));						}					} else {						_pageIsComplete = true;						dispatchEvent(new Event(CourseModel.PAGE_COMPLETE));					}					}			} else {				if (!_pageIsComplete)				{					_pageIsComplete = true;					dispatchEvent(new Event(CourseModel.PAGE_COMPLETE));				}			}			//Auto Nav to next page if this is set up.			if (courseAttributes.autoNavigation)			{				//Set up auto Nav Timer if needed				if (_autoNavTimer == null)				{					_autoNavTimer = new Timer(1000);					_autoNavTimer.addEventListener(TimerEvent.TIMER,autoNavToNextPage);				}				if (!_autoNavTimer.running && _autoNavTimer.hasEventListener(TimerEvent.TIMER))				{					_autoNavTimer.reset();					_autoNavTimer.start();				}			}		}				//Setter and Getter Methods		public function set audioStatus(p:String):void		{			if (p.toLowerCase() == "off")			{ 				_audioStatus = "off";			} else if (p.toLowerCase() == "on") {				_audioStatus = "on";			}			dispatchEvent(new Event(CourseModel.AUDIO_CHANGED));		}				public function get audioStatus():String		{			return _audioStatus;		}				public function set audioVolume(p:Number):void		{			_audioVolume = p;		}				public function get audioVolume():Number		{			return _audioVolume;		}				public function set indexState(s:String):void		{			if (s.toLowerCase() == "index")			{ 				_indexState = "index";			} else if (s.toLowerCase() == "read") {				_indexState = "read";			}			dispatchEvent(new Event(CourseModel.INDEX_CHANGED));						if (indexVisibleState == "hidden") indexVisibleState = "visible";		}				public function get indexState():String		{			return _indexState;		}				public function set indexVisibleState(s:String):void		{						if (s.toLowerCase() == "hidden")			{ 				_indexVisibleState = "hidden";			} else if (s.toLowerCase() == "visible") {				_indexVisibleState = "visible";			}			dispatchEvent(new Event(CourseModel.INDEX_VISIBILITYCHANGED));		}				public function get indexVisibleState():String		{			return _indexVisibleState;		}				//playState indicates the state of the play and pause button and therefore whether or not the media is playing		public function set playState(s:String):void		{			if (s.toLowerCase() == "pause")			{				_playState = "pause";			} else if (s.toLowerCase() == "play") {				_playState = "play";			}			trace("Event from CourseModel: MEDIA_CHANGED");			dispatchEvent(new Event(CourseModel.MEDIA_CHANGED));		}				public function get playState():String		{			return _playState;		}				public function set mediaControlVisible(b:Boolean):void		{			_mediaControlVisibility = b;			dispatchEvent(new Event(CourseModel.MEDIACONTROL_STATE));		}				public function get mediaControlVisible():Boolean		{			return _mediaControlVisibility;		}				public function set glossaryState(b:String):void		{			_glossaryState = b;			dispatchEvent(new Event(Model.GLOSSARY_CHANGE));		}				public function get glossaryState():String		{			return _glossaryState;		}				public function get lmsLink():LmsCom		{			return _lms;		}				public function get apiFound():Boolean		{			return _apiFound;		}				public function set feedbackPanel(p:InfoPanel):void		{			_feedbackPanel = p;		}				public function get feedbackPanel():InfoPanel		{			return _feedbackPanel;		}				public function set mainPlayer(p:MovieClip):void		{			_mainPlayer = p;		}				public function get mainPlayer():MovieClip		{			return _mainPlayer;		}				public function set curTopicMC(p:MovieClip):void		{			_curTopic_mc = p;		}				public function get curTopicMC():MovieClip		{			return _curTopic_mc;		}				public function set curPageMC(p:MovieClip):void		{			_curPage_mc = p;		}				public function get curPageMC():MovieClip		//Returns the currently selected page (movie clip) in the index. Pages without a TOC entry (istocentry = false) are not included.		{			return _curPage_mc;		}				public function set tocMC(p:MovieClip):void		{			_toc_mc = p;		}				public function get tocMC():MovieClip		{			return _toc_mc;		}				public function set connectString(s:String):void		{			_oldConnectString = _connectString;			_connectString = s;		}				public function get connectString():String		{			return _connectString;		}				public function set connectStringAS2(s:String):void		{			_connectStringAS2 = s;		}				public function get connectStringAS2():String		{			return _connectStringAS2;		}				public function get isPageComplete():Boolean		{			return _pageIsComplete;		}	}}