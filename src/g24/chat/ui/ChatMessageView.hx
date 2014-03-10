package g24.chat.ui;

import js.Browser.document;

class ChatMessageView extends DisplayElement {

	public function new( time : String, user : String, body : String ) {
		
		super();
		
		e.classList.add( 'message' );

		var e_user = document.createSpanElement();
		e_user.classList.add( 'user' );
		e_user.innerText = user;
		e.appendChild( e_user );

		var e_body = document.createSpanElement();
		e_body.classList.add( 'body' );
		e_body.innerText = body;
		e.appendChild( e_body );
		
		var e_date = document.createSpanElement();
		e_date.classList.add( 'date' );
		e_date.innerText = time;
		e.appendChild( e_date );
	}

	//public function appendBody( text : String ) {}
	
}
