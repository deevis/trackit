#!/usr/bin/ruby -w
#
# $Id: item_lookup1,v 1.6 2009/02/20 00:13:38 ianmacd Exp $

require 'amazon/aws'
require 'amazon/aws/search'

include Amazon::AWS
include Amazon::AWS::Search

# Example of a batch operation.
#
# The MerchantId restriction is to ensure that we retrieve only items that
# are for sale by Amazon. This is important when we later want to retrieve the
# availability status.
#
il = ItemLookup.new( 'ASIN', { 'ItemId' => 'B000AE4QEC',
			       'MerchantId' => 'Amazon' } )
il2 = ItemLookup.new( 'ASIN', { 'ItemId' => 'B000051WBE',
				'MerchantId' => 'Amazon' } )
il.batch( il2 )

# You can have multiple response groups.
#
rg = ResponseGroup.new( 'Medium', 'Offers', 'Reviews' )

req = Request.new('KIAJCBVJNAYXHQQNWDA')
req.locale = 'us'

resp = req.search( il, rg )
item_sets = resp.item_lookup_response[0].items

item_sets.each do |item_set|
  item_set.item.each do |item|
    attribs = item.item_attributes[0]
    puts attribs.label
    if attribs.list_price
      puts attribs.title, attribs.list_price[0].formatted_price
    end
  
    # Availability has become a cumbersome thing to retrieve in AWSv4.
    #
    puts 'Availability: %s' %
      [ item.offers[0].offer[0].offer_listing[0].availability ]
    puts 'Average rating: %s' % [ item.customer_reviews[0].average_rating ]
    puts 'Reviewed by %s customers.' %
      [ item.customer_reviews[0].total_reviews ]
  
    puts 'Customers said:'
    item.customer_reviews[0].review.each do |review|
      puts '  %s (%s votes)' % [ review.summary, review.total_votes ]
    end
  
    puts
  end
end

