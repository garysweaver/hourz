# HotCocoa 0.5.1 puts a to_plist on Object but a from_plist on HotCocoa. Having to include HotCocoa in your object in order to call read_plist is not intuitive and
# may cause adverse effects if having to extend Hash, Array, or Object with include HotCocoa. So instead, we add the same implementation plus a few lines to support 
# reading from files, etc. like from_json/from_xml in ActiveSupport implementations do. While at first Object doesn't seem an appropriate place to put this method, 
# it allows any object to have a from_plist class method as a companion to the to_plist instance method, which is intuitive. Examples:
# Hash.from_plist({:data=>'mydata'}.to_plist), Array.from_plist(['x','y','z'].to_plist), AnObject.from_plist(an_object.to_plist)
class Object
  
  # from_plist is the same as the HotCocoa 0.5.1 version. Could remove it, but keeping it here for now, in case need to debug.
  def self.from_plist(data, mutability=:all)
    # not sure if this will work
    if data.respond_to?(:read)
      data = data.read
    end
    mutability = case mutability
      when :none
        NSPropertyListImmutable
      when :containers_only
        NSPropertyListMutableContainers
      when :all
        NSPropertyListMutableContainersAndLeaves
      else
        raise ArgumentError, "invalid mutability `#{mutability}'"
    end
    if data.is_a?(String)
      data = data.dataUsingEncoding(NSUTF8StringEncoding)
      if data.nil?
        raise ArgumentError, "cannot convert string `#{data}' to data"
      end
    end
    #error = Pointer.new(:object)
    result = NSPropertyListSerialization.propertyListFromData(data,
      mutabilityOption:mutability,
      format:nil,
      errorDescription:nil)
    #raise error[0] if error[0].to_s.size > 0
  end
  
  # NSPropertyListSerialization can only take NSData, NSString, NSNumber, NSDate, NSArray, or NSDictionary object. Container objects must also contain only these kinds of objects.
  # So you must convert everything to either these types or hashes, arrays, strings, and other simple types before to_plist.
  def to_plist(format=:xml)
    format = case format
      when :xml
        NSPropertyListXMLFormat_v1_0
      when :binary
        NSPropertyListBinaryFormat_v1_0
      when :open_step
        NSPropertyListOpenStepFormat
      else
        raise ArgumentError, "invalid format `#{format}'"
    end
    #error = Pointer.new(:object)
    data = NSPropertyListSerialization.dataFromPropertyList(self,
      format:format,
      errorDescription:nil)
    #raise error[0] if error[0].to_s.size > 0
    NSMutableString.alloc.initWithData(data, encoding:NSUTF8StringEncoding)
  end
  
end
