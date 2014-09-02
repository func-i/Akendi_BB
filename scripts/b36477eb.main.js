(function(){var a,b,c,d,e,f,g,h,i,j;d=[],j=[],g=null,h=null,f=null,i={$html:$("html"),$allPages:$(".page"),$welcome:$(".welcome"),$startSession:$(".start-session"),$instructions:$(".instructions"),$start:$(".start"),$end:$(".end"),$practiceEnd:$(".practice.end"),$round1End:$(".round-1.end"),$nextRound:$(".next-round"),$toTest:$(".to-test"),$sessionEnd:$(".session.end"),$done:$(".done"),$inProgress:$(".in-progress"),$sentenceForm:$("#sentence-form"),$textarea:$("#sentence-form textarea"),$submit:$('#sentence-form input[type="submit"]'),$sentence:$("#sentence"),$admin:$("#admin"),$error:$("#error")},i.$html.on("click",function(a){var b;return a.preventDefault(),i.$textarea.focus(),b=i.$textarea.val().length,i.$textarea[0].setSelectionRange(b,b)}),i.$startSession.on("click",function(a){return a.preventDefault(),a.stopPropagation(),i.$allPages.hide(),e.initPractice()}),i.$textarea.on("keydown",function(a){return 8===a.which?a.preventDefault():void 0}),i.$textarea.on("input",function(a){var c,d,e;return g.isInProgress||g.isFinished||g.start(),g.isInProgress?(e=$(this).val(),c=_.reject(JsDiff.diffChars(g.actualText,e),function(a){return!a.added&&!a.removed}),g.actualText=e,d=new b({charCode:a.charCode,diffs:c,sentence:g}),g.inputs.push(d)):void 0}),i.$start.click(function(a){return a.preventDefault(),a.stopPropagation(),e.startTest()}),i.$toTest.click(function(a){return a.preventDefault(),a.stopPropagation(),i.$allPages.hide(),$(".round-1.instructions").show()}),i.$nextRound.click(function(a){return a.preventDefault(),a.stopPropagation(),i.$allPages.hide(),$(".round-2.instructions").show()}),i.$submit.click(function(a){return a.preventDefault(),g.isInProgress?(a.stopPropagation(),g.stop(),e.outOfTime()?e.stopTest():e.showNextSentence()):void 0}),b=function(){function a(a){this.diffs=a.diffs,this.sentence=a.sentence,this.index=this.sentence.inputs.length,this.setWhoDunnit(),this.setTimeSinceStart()}return a.prototype.setWhoDunnit=function(){var a;return a=1===this.diffs.length&&this.diffs[0].added&&1===this.diffs[0].value.length&&this.diffs[0].value===this.sentence.actualText[this.sentence.actualText.length-1],this.whoDunnit=a?"user":"OS"},a.prototype.setTimeSinceStart=function(){var a;return a=(new Date).getTime(),0===this.index&&(this.sentence.startTime=a),this.timeSinceStart=a-this.sentence.startTime},a.prototype.abbrDiffs=function(){var a,b,c,d,e,f,g;for(b=[],g=this.diffs,e=0,f=g.length;f>e;e++)c=g[e],d=c.added?"insert":"delete",a={type:d,value:c.value},b.push(a);return b},a.prototype.abbrSelf=function(){return{index:this.index,whoDunnit:this.whoDunnit,diffs:this.abbrDiffs(),timeSinceStart:this.timeSinceStart}},a}(),c=function(){function a(a){this.parseObj=a.parseObj,this.isCurrent=!1,this.expectedText=this.parseObj.get("text"),this.isPractice=this.parseObj.get("isPractice"),this.round=this.parseObj.get("round"),this.actualText="",this.inputs=[]}return a.prototype.makeCurrent=function(){return g=this,this.loadText()},a.prototype.loadText=function(){return i.$sentence.text(this.expectedText)},a.prototype.setSpeedInWpm=function(){var a,b;return b=this.timeInMs/1e3/60,a=this.actualText.length/5/b,this.speedInWpm=Math.round(100*a)/100},a.prototype.start=function(){return this.isInProgress=!0},a.prototype.stop=function(){return this.timeInMs=(new Date).getTime()-this.startTime,this.actualText=i.$textarea.val(),this.setSpeedInWpm(),this.isInProgress=!1,this.isFinished=!0,e.isPractice?void 0:this.saveToParse()},a.prototype.saveToParse=function(){var a,b,c,d,f,g;for(b=[],g=this.inputs,d=0,f=g.length;f>d;d++)a=g[d],b.push(a.abbrSelf());return c=new e.parse.objects.Test,c.set("inputs",b),c.set("testerId",h.id),c.set("participantId",h.get("participantId")),c.set("round",this.round),c.set("actualText",this.actualText),c.set("expectedText",this.expectedText),c.set("timeInMs",this.timeInMs),c.set("speedInWpm",this.speedInWpm),c.save()},a}(),a=function(){function a(){this.initParse(),FastClick.attach(document.body),this.isAdmin()?(this.generateCSVs().then(function(){return i.$admin.show()}).fail(function(){return i.$error.show()}),i.$html.off("click")):this.init().then(function(a){return function(){return a.initSession()}}(this))}return a.prototype.initSession=function(){return i.$welcome.show()},a.prototype.initParse=function(){return Parse.initialize("wn0yAEDFtIJ9Iw3jrL8hBJBeFbjQkVaJvnmY1CS3","KBmFKqYHviQnxPQhQe9U7VOWg5E5LjFFKoqzC7ay"),this.parse={objects:{Sentence:Parse.Object.extend("Sentence"),Test:Parse.Object.extend("Test"),Tester:Parse.Object.extend("Tester"),Config:Parse.Object.extend("Config")},api:{getConfig:function(a){return function(){var b;return b=new Parse.Query(a.parse.objects.Config),b.first()}}(this),createTester:function(a){return function(){var b;return b=new Parse.Query(a.parse.objects.Tester),b.limit(1e3).find().then(function(b){var c;return c=new a.parse.objects.Tester,c.set("participantId",b.length+1),c.save()}).fail(function(){return a.parse.api.createTester()})}}(this),getSentences:function(a){return function(){var b;return b=new Parse.Query(a.parse.objects.Sentence),b.find()}}(this),getTests:function(a){return function(){var b,c,d,e;return b=new Parse.Promise,e=[],d=new Parse.Query(a.parse.objects.Test),d.limit(1e3),c=function(a){return d.skip(a).find().then(function(a){return e.push(a),e=_.flatten(e),1e3===a.length?c(e.length):b.resolve(e)})},c(0),b}}(this)}}},a.prototype.init=function(){return Parse.Promise.when(this.parse.api.getConfig(),this.parse.api.createTester(),this.parse.api.getSentences()).done(function(a){return function(b,e,f){var g,i,j,k,l,m;for(a.config=b,h=e,l=_.shuffle(f),m=[],j=0,k=l.length;k>j;j++)i=l[j],g=new c({parseObj:i}),m.push(d.push(g));return m}}(this))},a.prototype.isAdmin=function(){var a;return a=document.createElement("a"),a.href=window.location,"#admin"===a.hash},a.prototype.maxTime=function(){return this.config.get(this.isPractice?"practiceTime":"experimentTime")},a.prototype.outOfTime=function(){return(new Date).getTime()-this.startTime>this.maxTime()},a.prototype.startTest=function(){return j[0].makeCurrent(),this.startTime=(new Date).getTime(),i.$allPages.hide(),i.$inProgress.show(),i.$textarea.val(""),i.$textarea.focus()},a.prototype.stopTest=function(){var a;return this.isPractice?(a=i.$practiceEnd,j=_.where(d,{round:1}),this.round=1,this.isPractice=!1):1===this.round?(a=i.$round1End,j=_.where(d,{round:2}),this.round=2):2===this.round&&(a=i.$sessionEnd),i.$allPages.hide(),a.show(),i.$html.off("click")},a.prototype.showNextSentence=function(){var a;return a=j.indexOf(g),j[a+1].makeCurrent(),i.$textarea.val(""),i.$textarea.focus()},a.prototype.initPractice=function(){return $(".practice.instructions").show(),this.isPractice=!0,j=_.where(d,{isPractice:!0})},a.prototype.generateCSVs=function(){return this.parse.api.getTests().then(function(a){var b,c,d,e,f,g,h,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K;for(t=[],p=[],G=_.sortBy(a,function(a){return a.createdAt}),w=0,A=G.length;A>w;w++)k=G[w],n=k.toJSON(),n.id=k.id,t.push(n),-1===p.indexOf(n.testerId)&&p.push(n.testerId);for(K=[],x=0,B=p.length;B>x;x++){for(o=p[x],q=_.where(t,{testerId:o}),s=[],H=_.sortBy(q,function(a){return a.createdAt}),y=0,C=H.length;C>y;y++){for(l=H[y],h=[],I=l.inputs,z=0,D=I.length;D>z;z++){if(f=I[z],"user"===f.whoDunnit)g="user: '"+f.diffs[0].value+"' ("+f.timeSinceStart+")";else{for(e=[],J=f.diffs,F=0,E=J.length;E>F;F++)d=J[F],e.push("["+d.type+": '"+d.value+"']");g="OS: "+e+" ("+f.timeSinceStart+")"}h.push(g)}m={Id:l.id,Round:l.round,Stimuli:l.expectedText,Response:l.actualText,Inputs:h.join("\n"),"Total Time (ms)":l.timeInMs,"Total Time (s)":l.timeInMs/1e3,"Pressed Characters":l.actualText.length,"Pressed Words":l.actualText.length/5,"Words/Minute":l.speedInWpm,C_Error:0,LS_Error:0,DS_Error:0,VA_Error:0,HA_Error:0,IC_Error:0,FL_Error:0,DC_Error:0,AC_Error:0,Other:0,Autocomplete:_.where(l.inputs,{whoDunnit:"OS"}).length},s.push(m)}j=new Date,v=""+j.getFullYear()+"-"+j.getMonth()+"-"+j.getDate()+"-"+j.getTime(),r=JSONToCSVConvertor(s,"Participant "+l.participantId,!0),u="data:text/csv;charset=utf-8,"+encodeURIComponent(r),b=$("<div/>"),c=$("<a/>",{href:u,download:"participant-"+l.participantId+"-"+v+".csv",html:"Participant "+l.participantId,"class":"btn btn-success"}).appendTo(b),K.push(b.appendTo(i.$admin))}return K})},a}(),e=new a}).call(this);