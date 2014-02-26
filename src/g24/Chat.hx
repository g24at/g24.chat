package g24;

import js.Browser;
import js.Browser.document;
import js.Browser.window;
import js.html.Element;
import jabber.client.Stream;
import jabber.client.MUChat;

class Chat {

	static inline var HOST = 'jabber.spektral.at';
	static inline var MUC_HOST = 'conference.jabber.spektral.at';
	static inline var MUC_ROOM = 'g24';

	static var storage = Browser.getLocalStorage();
	static var nick : String;
	static var stream : Stream;
	static var muc : MUChat;
	static var e : Element;

	static function join( nick : String ) {
		Chat.nick = nick;
		if( stream == null )
			connect();
		else
			joinMUChat();
	}

	static function connect() {
		document.body.innerText = 'Connecting ...';
		var cnx = new jabber.BOSHConnection( HOST, HOST+'/http' );
		stream = new Stream( cnx );
		stream.onOpen = function(){
			var auth = new jabber.client.Authentication( stream, [new jabber.sasl.AnonymousMechanism()] );
			auth.onSuccess = handleLogin;
			auth.onFail = function(?e){
				trace("auth failed "+e);
			}
			auth.start( null, null );
		}
		stream.onClose = function(?e){

		}
		stream.open( null );
	}

	static function disconnect() {
		if( stream != null ) {
			if( muc.joined )
				muc.leave();
			stream.close( true );
		}
	}

	static function handleLogin() {
		trace("connected!");
		joinMUChat();
	}

	static function joinMUChat() {
		
		muc = new MUChat( stream, MUC_HOST, MUC_ROOM );
		muc.onJoin = handleMUCJoin;
		muc.onPresence = handleMUCPresence;
		muc.onMessage = handleMUCMessage;
		muc.onSubject = handleMUCSubject;
		muc.onLeave = function(){ trace('left room'); }
		muc.onError = function(e){
			trace(e);
			document.body.innerHTML = '<div class="error">$e</div>';
		}
		muc.join( nick );

		printTemplate( 'muc' );
	}

	static function handleMUCJoin() {

		storage.setItem( 'muc_nick', Chat.nick );

		getElementById( 'chat_speak' ).onclick = function(_){ submitMessage(); }
		document.body.onkeydown = function(e){
			switch e.keyCode {
			case 13: submitMessage();
			}
		}
	}

	static function handleMUCSubject( o : String, subject : String ) {
		trace("subject changed "+subject );
	}

	static function handleMUCPresence( o : jabber.client.MUChatOccupant ) {
		
		//trace("pppppppppp "+o);
		//trace(o.nick+":"+Chat.nick);
		
		if( o == null || o.nick == Chat.nick )
			return;

		if( o.presence.type == unavailable ) {
			getElementById( 'chat_user_'+o.nick ).remove();
			return;
		}
			
		var e = document.createDivElement();
		e.id = 'chat_user_'+o.nick;
		e.classList.add( 'chat_user' );
		e.innerText = o.nick;
		getElementById('chat_users').appendChild( e );
	}

	static function handleMUCMessage( o : jabber.client.MUChatOccupant, m : xmpp.Message ) {
		
		if( o == null )
			return;

		var e = document.createDivElement();
		e.classList.add( 'message' );

		var time : String = null;
		var delay = xmpp.Delayed.fromPacket( m );
		if( delay == null ) {
			var now = Date.now();
			time = now.getHours()+":"+now.getMinutes()+":"+now.getSeconds();
 		} else {
 			time = delay.stamp;
		}
		var e_date = document.createSpanElement();
		e_date.classList.add( 'date' );
		e_date.innerText = time+' / ';
		e.appendChild( e_date );

		var e_user = document.createSpanElement();
		e_user.classList.add( 'user' );
		e_user.innerText = o.nick+" / ";
		e.appendChild( e_user );

		var e_body = document.createSpanElement();
		e_body.classList.add( 'body' );
		e_body.innerText = m.body;
		e.appendChild( e_body );
		
		getElementById( 'chat_output' ).appendChild( e );
	}

	static function submitMessage() {
		var e_textinput = getElementById( 'chat_textinput' );
		var text : String = untyped e_textinput.value;
		if( text.length == 0 )
			return;
		muc.speak( text );
		untyped e_textinput.value = '';
	}

	static function printTemplate( id : String, ?ctx : Dynamic ) {
		if( ctx == null ) ctx = {};
		var html = new haxe.Template( haxe.Resource.getString( id ) ).execute( ctx );
		document.body.innerHTML = html;
	}

	static function onUnload(e) {
		e.preventDefault();
		e.stopPropagation();
		//untyped alert('onunload');
		disconnect();
		return false;
	}

	static inline function getElementById( id ) : Element return document.getElementById(id);

	static function main() {

		window.onload = function(_){

			printTemplate( 'login' );
			
			var e_nickname = getElementById( 'chat_nickname' );

			var nickname = storage.getItem( 'muc_nick' );
			if( nickname != null ) {
				untyped e_nickname.value = nickname;
			}

			document.getElementById( 'chat_join' ).onclick = function(e) {
				trace(e);
				var nick : String = untyped e_nickname.value;
				if( nick.length < 1 )
					return;
				join( nick );
			};
		}
		window.onbeforeunload = onUnload;
		window.onunload = onUnload;
	}

}
