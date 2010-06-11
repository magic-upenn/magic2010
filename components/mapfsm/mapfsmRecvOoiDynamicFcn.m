function mapfsmRecvOoiDynamic(data, name)

global MP OOI_DYNAMIC

if ~isempty(data)
  OOI_DYNAMIC = deserialize(data);
  MP.sm = setEvent(MP.sm, 'track');
end
