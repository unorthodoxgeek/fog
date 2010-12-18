module Fog
  module AWS
    class DNS
      class Real

        require 'fog/aws/parsers/dns/change_resource_record_sets'

        # Use this action to create or change your authoritative DNS information for a zone
        #
        # ==== Parameters
        # * zone_id<~String> - ID of the zone these changes apply to
        # * options<~Hash>
        #   * comment<~String> - Any comments you want to include about the change.
        #   * change_batch<~Array> - The information for a change request
        #     * changes<~Hash> -
        #       * action<~String> -  'CREATE' or 'DELETE'
        #       * name<~String> - This must be a fully-specified name, ending with a final period
        #       * type<~String> - A | AAAA | CNAME | MX | NS | PTR | SOA | SPF | SRV | TXT 
        #       * ttl<~Integer> - 
        #       * resource_record<~String>
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ChangeInfo'<~Hash>
        #       * 'Id'<~String> - The ID of the request
        #       * 'Status'<~String> - status of the request - PENDING | INSYNC
        #       * 'SubmittedAt'<~String> - The date and time the change was made
        #   * status<~Integer> - 201 when successful
        def change_resource_record_sets(zone_id, change_batch, options = {})

          # AWS methods return zone_ids that looks like '/hostedzone/id'.  Let the caller either use 
          # that form or just the actual id (which is what this request needs)
          zone_id = zone_id.sub('/hostedzone/', '')

          optional_tags = ''
          options.each { |option, value|
            case option
            when :comment
              optional_tags+= "<Comment>#{value}</Comment>"
            end
          }
          
          #build XML
          if change_batch.count > 0
            
            changes= "<ChangeBatch>#{optional_tags}<Changes>"
            
            change_batch.each { |change_item|
              action_tag = %Q{<Action>#{change_item[:action]}</Action>}
              name_tag = %Q{<Name>#{change_item[:name]}</Name>}
              type_tag = %Q{<Type>#{change_item[:type]}</Type>}
              ttl_tag = %Q{<TTL>#{change_item[:ttl]}</TTL>}
              resource_records= change_item[:resource_records]
              resource_record_tags = ''
              resource_records.each { |record|
                resource_record_tags+= %Q{<ResourceRecord><Value>#{record}</Value></ResourceRecord>}
              }
              resource_tag=  %Q{<ResourceRecords>#{resource_record_tags}</ResourceRecords>}
              
              change_tags = %Q{<Change>#{action_tag}<ResourceRecordSet>#{name_tag}#{type_tag}#{ttl_tag}#{resource_tag}</ResourceRecordSet></Change>}
              changes+= change_tags
            }          
            
            changes+= '</Changes></ChangeBatch>'
          end

          body =   %Q{<?xml version="1.0" encoding="UTF-8"?><ChangeResourceRecordSetsRequest xmlns="https://route53.amazonaws.com/doc/2010-10-01/">#{changes}</ChangeResourceRecordSetsRequest>}
          request({
            :body       => body,
            :parser     => Fog::Parsers::AWS::DNS::ChangeResourceRecordSets.new,
            :expects    => 200,
            :method     => 'POST',
            :path       => "hostedzone/#{zone_id}/rrset"
          })

        end

      end

      class Mock

        def change_resource_record_sets(zone_id, change_batch, options = {})
          Fog::Mock.not_implemented
        end

      end
    end
  end
end
