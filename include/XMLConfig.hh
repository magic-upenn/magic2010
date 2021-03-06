//source XMLConfig.hh (gazebo)

#ifndef XMLCONFIG_HH
#define XMLCONFIG_HH

#include <libxml/parser.h>
#include <libxml/xpath.h>
#include <string>

#include "Vector3.hh"
#include "Vector4.hh"
#include "Vector2.hh"
#include "Quatern.hh"
#include "Time.hh"

namespace gazebo
{
  
  // Forward declarations
  class XMLConfigNode;
  
  /// \addtogroup gazebo_server
  /// \brief XML parser
  /// \{
  
  /// \brief XML parser
  class XMLConfig
  {
    /// \brief Constructor
    public: XMLConfig();
  
    /// \brief Destructor
    public: ~XMLConfig();
  
    /// \brief Load config from an XML file
    public: void Load(const std::string &filename );
  
    /// \brief Load config from an XML string
    public: void LoadString(const std::string &str );
  
    /// \brief Save config back into file
    ///        Set filename to NULL to save back into the original file
    public: int Save(const std::string &filename );
  
    /// \brief Get the root node
    public: XMLConfigNode *GetRootNode() const;

    /// \brief Fill the document with information
    private: void FillDocumentNodes();
 
    /// \brief Create wrappers
    private: XMLConfigNode *CreateNodes( XMLConfigNode *parent, 
                                         xmlNodePtr xmlNode );
    /// \brief File name
    public: std::string filename;
    
    /// \brief XML data
    private: xmlDocPtr xmlDoc;
  
    /// \brief The root of the tree
    private: XMLConfigNode *root;
  
    private: xmlXPathContextPtr xpathContex;
  };
  
  
  /// \brief Class encapsulating a single xml node
  class XMLConfigNode
  {
    /// \brief Constructor
    public: XMLConfigNode( XMLConfig *cfg, XMLConfigNode *parent, 
                          xmlNodePtr xmlNode, xmlDocPtr xmlDoc );
  
    /// \brief Destructors
    public: ~XMLConfigNode();
  
    /// \brief Get the node name
    public: std::string GetName() const;
  
    /// \brief Get the name space prefix
    public: std::string GetNSPrefix() const;
  
    /// \brief Get the next sibling of this node
    public: XMLConfigNode *GetNext() const;

    /// \brief Get next by name
    public: XMLConfigNode *GetNext(const std::string &name,const std::string &prefix=std::string()) const;

    /// \brief Get next node by namespace prefix
    public: XMLConfigNode *GetNextByNSPrefix(const std::string &prefix) const;
  
    /// \brief Get the first child of this node
    public: XMLConfigNode *GetChild() const;
  
    /// \brief Get a child based on a name. Returns null if not found
    public: XMLConfigNode *GetChild(const std::string &name, const std::string &prefix=std::string() ) const;
  
    /// \brief Get the first child with the specified namespace prefix
    public: XMLConfigNode *GetChildByNSPrefix(const std::string &prefix ) const;
  
    /// \brief Move child pointer back to beginning
    public: XMLConfigNode *Rewind();
  
    /// \brief Print (for debugging purposes)
    public: void Print();

    /// \brief Get the parent
    public: XMLConfigNode * GetParent();

    /// \brief Get the root node
    public: XMLConfigNode * GetRoot();
  
    /// \brief Return the value of the current node
    public: std::string GetValue() const;
  
    /// \brief Get an attribute string value
    public: std::string GetString( const std::string &key, 
                                   const std::string &def, 
                                   int require = 0 ) const;
  
    /// \brief Get a attribute character value
    public: unsigned char GetChar( const std::string &key, char def, int require = 0 ) const;
  
    /// \brief Get a file name.  Always returns an absolute path.  
    ///        If the filename is entered as a relative path, we prepend the 
    ///        world file path.
    public: std::string GetFilename( const std::string &key, const std::string &def, 
                                     int require = 0) const;
  
    /// \brief Get an integer
    public: int GetInt( const std::string &key, int def, int require = 0 ) const;
  
    /// \brief Get a double
    public: double GetDouble( const std::string &key, double def, int require = 0 ) const;
  
    /// \brief Get a float
    public: float GetFloat( const std::string &key, float def, int require = 0 ) const;
  
    /// \brief Get a boolean
    public: bool GetBool( const std::string &key, bool def, int require = 0 ) const;
  
    /// \brief Get an attribute length value (return value in meters)
    public: double GetLength( const std::string &key, double def, int require = 0 ) const;
  
    /// \brief Get an attribute time value (return value in seconds)
    public: gazebo::Time GetTime( const std::string &key, double def, int require = 0 ) const;
  
    /// \brief Get a position
    public: Vector3 GetVector3( const std::string &key, Vector3 def, int require = 0 ) const;

    /// \brief Get a four dimensional double vector
    public: Vector4 GetVector4( const std::string &key, Vector4 def, int require = 0 ) const;
  
    /// \brief Get a two dimensional double vector
    public: Vector2<double> GetVector2d( const std::string &key, Vector2<double> def ) const;

    /// \brief Get a two dimensional int vector
    public: Vector2<int> GetVector2i( const std::string &key, Vector2<int> def ) const;
  
    /// \brief Get a rotation
    public: Quatern GetRotation( const std::string &key, Quatern def ) const;
  
    /// \brief Get an attribute tuple value
    public: std::string GetTupleString( const std::string &key, int index, 
                                        const std::string &def ) const;
  
    /// \brief Get an attribute tuple int value
    //public: int GetTupleInt( const std::string &key, int index, int def ) const;
    public: int GetTupleInt( const std::string &key, int index, int def, int require = 0) const;
  
    /// \brief Get an attribute tuple double value
    public: double GetTupleDouble( const std::string &key, int index, double def, int require = 0 ) const;
  
    /// \brief Get an attribute tuple length value (return value in meters)
    public: double GetTupleLength( const std::string &key, int index, double def ) const;
  
    /// \brief Get an attribute tuple angle value (return value in radians)
    public: double GetTupleAngle( const std::string &key, int index, double def ) const;
  
    /// \brief Set a node's value, either attribute or child node value, maybe create it
    /// \param key : the name of the element or attribute to write 
    /// \param value : the name of the element or attribute to write
    /// \param require : Require=1 means that if not found a new node will be created
    /// \param type : Only if a new node is created, the type must be specified
    public: XMLConfigNode * SetValue(const std::string &key, const std::string &data, int require =0, int type=0);

    /// \brief Get a node's value, which is either a attribute or child node value.
    protected: xmlChar* GetNodeValue( const std::string &key ) const;
  
    /// \brief Set a node's value, either attribute or child node value (private)
    protected: XMLConfigNode * SetNodeValue(const std::string& key,const std::string& value);

    /// \brief Creates a new node child of this. either attribute or element
    public: XMLConfigNode * NewNode(const char* key, const char* value, int type);

    /// \brief Our document
    private: XMLConfig *config;
    
    /// \brief Our parent
    private: XMLConfigNode *parent;
    
    /// \brief Our siblings
    private: XMLConfigNode *next, *prev;
    
    /// \brief Our children
    private: XMLConfigNode *childFirst, *childLast;
  
    /// \brief XML data
    private: xmlNodePtr xmlNode;
  
    /// \brief XML data
    private: xmlDocPtr xmlDoc;
  };


  /// \}
}

#endif

