/*
 *  Gazebo - Outdoor Multi-Robot Simulator
 *  Copyright (C) 2003  
 *     Nate Koenig & Andrew Howard
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */
/* Desc: Singleton base class
 * Author: Nate Koenig
 * Date: 2 Sept 2007
 * SVN: $Id: SingletonT.hh 7042 2008-09-24 18:09:46Z natepak $
 */

#ifndef SINGLETONT_HH
#define SINGLETONT_HH

template < class DOOMED >
class DestroyerT;

/// \brief Singleton class
template <class T>
class SingletonT
{
  /// \brief Get an instance of the singleton
  public: static T *Instance()
          {
            if (!myself)
            {
              myself = new T();
              destroyer.SetDoomed(myself);
            }

            return myself;
          }

  /// \brief Constructor
  protected: SingletonT() {}

  /// \brief Destructor
  protected: virtual ~SingletonT() {}

  private: static DestroyerT< T > destroyer;
  private: static T *myself;
};

template <class T>
DestroyerT<T> SingletonT< T >::destroyer;

template <class T>
T *SingletonT<T>::myself = 0;



/// \brief Destroyer
template < class DOOMED >
class DestroyerT 
{

  /// \brief Constructor
  public: DestroyerT(DOOMED* = 0);

  /// \brief Destructor
  public: ~DestroyerT();

  /// \brief Sets the class to be cleaned
  public: void SetDoomed(DOOMED*);

  /// \brief Prevent users from making copies of a
  ///        Destroyer to avoid double deletion:
  private: DestroyerT(const DestroyerT<DOOMED>&);

  /// \brief Equal operator
  private: DestroyerT<DOOMED>& operator=(const DestroyerT<DOOMED>&);

  private: DOOMED* doomed;
};

template <class DOOMED>
DestroyerT<DOOMED>::DestroyerT( DOOMED* d ) 
{
  doomed = d;
}

template <class DOOMED>
DestroyerT<DOOMED>::~DestroyerT() {
  delete doomed;
}

template <class DOOMED>
void DestroyerT<DOOMED>::SetDoomed( DOOMED* d )
{
  doomed = d;
}

#endif
