xquery version "1.0-ml";

module namespace resource = "http://marklogic.com/rest-api/resource/loadSampleData";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

declare namespace dir = "http://marklogic.com/xdmp/directory";

declare function get(
	$context as map:map,
	$params  as map:map
	) as document-node()*
{
	xdmp:log("GET called")
};

declare function put(
	$context as map:map,
	$params  as map:map,
	$input   as document-node()*
	) as document-node()?
{

for $file in xdmp:filesystem-directory("/tmp/quicksave/")/dir:entry/dir:filename
let $_ := xdmp:sleep(6)
return xdmp:document-load("/tmp/quicksave/" || $file/node() ,
            <options xmlns="xdmp:document-load">
                <uri>{xdmp:url-decode($file/node())}</uri>
                <repair>full</repair>
                <permissions>{xdmp:default-permissions()}</permissions>
                <format>xml</format>
                <collections>
                  <collection>EmployeeSkills</collection>
                </collections>
            </options>)

};

declare function post(
	$context as map:map,
	$params  as map:map,
	$input   as document-node()*
	) as document-node()*
{
	xdmp:log("POST called")
};

declare function delete(
	$context as map:map,
	$params  as map:map
	) as document-node()?
{
	xdmp:log("DELETE called")
};

declare function loadUSData(
	$username as xs:string
	)
{
	for $file in fn:collection("sample-customers")
	return
	 try{
		let $uri-prefix := "/" || $username
		let $lines :=
			if (fn:contains($file, "\n")) then
				tokenize($file, "\n")
			else
				tokenize($file, "\r")
		let $head := tokenize($lines[1], ',')
		let $body := remove($lines, 1)
		for $line at $idx in $body
		let $fields := tokenize($line, ',')
		let $doc :=
			<root>
				{
					for $key at $pos in $head
					let $value := $fields[$pos]
					return element {functx:trim($key)} {functx:trim($value)}
				}
			</root>
		return
			xdmp:document-insert(
				fn:concat(
					$uri-prefix,
					xdmp:node-uri($file),
					"/",
					$doc//id[1]/text(),
					".xml"
				),
				$doc,
				(),
				fn:concat($username, '-entities')
			)
	 }catch($e){
		 xdmp:set-response-code(500, "Internal Server Error")
	 }
};

declare function loadInternationalData(
	$username as xs:string
	)
{
	let $_ := xdmp:log("loading international customers")
	let $policy-ids := fn:collection("sample-policy-identifiers")/policy_ids/policy_id
	for $file in fn:collection("international-customers")
	let $data :=
		(: Remove the XML version and encoding data before processing. :)
		if (fn:starts-with($file, "<?xml")) then
			let $rec-idx := functx:index-of-string-first($file, "<record>")
			return fn:substring($file, $rec-idx)
		else
			$file

	let $custs := xdmp:unquote(fn:concat("<records>", $data, "</records>"))
	return
		try {
			let $uri-prefix := "/" || $username
			let $lines := $custs/records/record
			return
				for $line at $idx in $lines
				let $doc := <root>
					{
						$line/*,
						$policy-ids[$idx]
					}
				</root>

				return
					xdmp:document-insert(
						fn:concat(
							$uri-prefix,
							xdmp:node-uri($file),
							"/",
							$idx,
							".xml"
						),
						$doc,
						(),
						fn:concat($username, '-entities')
					)
		 } catch($e) {
			 xdmp:set-response-code(500, "Internal Server Error")
		 }
};