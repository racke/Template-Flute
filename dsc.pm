Hi,

So my idea of solving that is as follows:

We use current system with separate XML specs, that is another mater.

I tried to describe it with words, but its hard :) 
Ill just do it in metacode. It is of course very basic, but just to get an idea and to see if there is some mayor design flaw.

return process( $whole_html, $whole_specs )->sprint


sub process(){
	# html_object and spects are whole documents on fist level, and copy of subset in deeper copies
	$html_object, $specs_object = @_
	
	for $spec ($specs_object){
		if ($spec == "simple (not iterator)") {
			replace_or_something( $html_object, $spec, $value )
		} 
		elsif ($spec == "complex (iterator)") {
			$target_html_object_to_modify = $html_object->find( $spec->some_kind_of_selector )
			$html_element_template = $target_html_object_to_modify->copy()
			$html_object->remove($target_html_object_to_modify)
			for element (list){
				# Now the recursive request
				$html_object->append( $spec->some_kind_of_selector, process( $html_element_template, $specs_subset_children ) ) 
			}
		} 
	}
	return $html_object
}

sub replace_or_something(){
	$html_object, $spec, $value = @_
	$object_ref = $html_object->find( $spec->some_kind_of_selector )
	$object_ref->set($value)
}

