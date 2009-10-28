# partigirb

A Ruby wrapper for the Partigi API, adapted from [Grackle](http://github.com/hayesdavis/grackle/tree/master) by Hayes Davis.

## What is Partigi?

[Partigi](http://www.partigi.com) is a service that helps you choose your next cultural items, share short reviews and keep track of what you have consumed and own.

The Partigi API is an almost-REST based Atom API where we offer you almost all data and functionality that you have in the website.

There is also a [complete documentation of the API](http://partigi.pbworks.com/).

## Install

    gem install partigirb -s http://gemcutter.org

## Usage

### Creating a client

#### Without Authentication

    client = Partigirb::Client.new

#### With Authentication

    client = Partigirb::Client.new(:auth => {:login => 'SOMEUSERLOGIN', :api_secret => 'SECRETGENERATEDFORTHEUSER'})
  
#### With specific API version
  
    client = Partigirb::Client.new(:api_version => 2)
  
### Request methods

A request to Partigi servers is done by translating Partigi URL paths into a set of chained method calls, just changing slashes by dots. Each call is used to build the request URL until a format call is found which causes the request to be sent. In order to specify the HTTP method use:

- `?` for HTTP GET
- `!` for HTTP POST (in this case you will need to use a client with authentication)

A request is not performed until either you add the above signs to your last method call or you use a format method call.

**Note:** Any method call that is not part of a valid API request path will be chained to the  request that Partigirb sends to the server, so that when the client finds a format call (method call ending with ? or !) a wrong request will be sent and a PartigiError will be raised. For example:

      client.wrong.items.index?
      
or
      
      client.wrong
      client.items.index?

In the second case we do the wrong call and the right one in separated sentences, however the wrong call is chained anyway (in that case the client method `clear` may be used to flush the chain).

### Formats

The response format is specified by a method call with the format name (atom, json or xml). Notice that the only format fully implemented on Partigi API at the moment is atom, which is the default used by the wrapper.

### Example requests

The simplest way of executing a GET request is to use the `?` notation, using the default format.

    client.users.show? :id => 'johnwayne'     # http://www.partigi.com/api/v1/users/show.atom?id=johnwayne
  
Also you can force the format:
  
    client.users.show.json? :id => 'johnwayne' # http://www.partigi.com/api/v1/users/show.json?id=johnwayne

For POST requests just change `?` by `!`:
  
    client.reviews.update! :id => 123, :status => 1 # POST to http://www.partigi.com/api/v1/reviews/update.atom
  

### Parameter handling

- All parameters are URL encoded as necessary.
- If you use a File object as a parameter it will be POSTed to Partigi in a multipart request.
- If you use a Time object as a parameter, .httpdate will be called on it and that value will be used

### Return values

The returned values are always OpenStruct objects (wrapped in Partigirb::PartigiStruct) containing the response values as attributes. 

If the response contains several entries the client returns an Array of OpenStruct objects.

When using Atom format Partigi returns some XML elements using namespaces. In those cases the elements are mapped to attributes by convention, for example: `namespaceName:attribute` becomes `namespaceName_attribute`

#### Special cases

There are two special cases to be aware of in regard to PartigiStruct:

- Every attribute which name is equal to any of the Ruby Object methods (e.g `type`) will be mapped to a method on the struct starting with an underscore (e.g `_type`).

- XML elements that appear repeated with different type values will turn into a unique struct with one method per type. For instance:

        <content type="text">Some text</content>
        <content type="html"><p>Some html</p></content>
  
  Will be accessed by `result.content.text` and `result.content.html`, both returning a ruby string.

### Error handling

In case Partigi returns an error response, this is turned into a PartigiError object which message attribute is set to the error string returned in the XML response.

## Requirements

- json
- mime-types

## Copyright

Copyright (c) 2009 Alvaro Bautista & Fernando Blat, released under MIT license
