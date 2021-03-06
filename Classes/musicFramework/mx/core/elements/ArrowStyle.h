// MusicXML Class Library
// Copyright (c) by Matthew James Briggs
// Distributed under the MIT License

#pragma once

#include "../../core/ForwardDeclare.h"
#include "../../core/ElementInterface.h"
#include "../../core/Enums.h"

#include <iosfwd>
#include <memory>
#include <vector>

namespace mx
{
    namespace core
    {

        MX_FORWARD_DECLARE_ELEMENT( ArrowStyle )

        inline ArrowStylePtr makeArrowStyle() { return std::make_shared<ArrowStyle>(); }
		inline ArrowStylePtr makeArrowStyle( const ArrowStyleEnum& value ) { return std::make_shared<ArrowStyle>( value ); }
		inline ArrowStylePtr makeArrowStyle( ArrowStyleEnum&& value ) { return std::make_shared<ArrowStyle>( std::move( value ) ); }

        class ArrowStyle : public ElementInterface
        {
        public:
            ArrowStyle();
            ArrowStyle( const ArrowStyleEnum& value );

            virtual bool hasAttributes() const;
            virtual bool hasContents() const;
            virtual std::ostream& streamAttributes( std::ostream& os ) const;
            virtual std::ostream& streamName( std::ostream& os ) const;
            virtual std::ostream& streamContents( std::ostream& os, const int indentLevel, bool& isOneLineOnly ) const;
            ArrowStyleEnum getValue() const;
            void setValue( const ArrowStyleEnum& value );

            bool fromXElement( std::ostream& message, xml::XElement& xelement );

        private:
            ArrowStyleEnum myValue;
        };
    }
}
