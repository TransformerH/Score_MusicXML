// MusicXML Class Library
// Copyright (c) by Matthew James Briggs
// Distributed under the MIT License

#pragma once

#include "../../core/ForwardDeclare.h"
#include "../../core/AttributesInterface.h"
#include "../../core/Strings.h"

#include <iosfwd>
#include <memory>
#include <vector>

namespace mx
{
    namespace core
    {

        MX_FORWARD_DECLARE_ATTRIBUTES( ScorePartwiseAttributes )

        struct ScorePartwiseAttributes : public AttributesInterface
        {
        public:
            ScorePartwiseAttributes();
            virtual bool hasValues() const;
            virtual std::ostream& toStream( std::ostream& os ) const;
            XsToken version;
            bool hasVersion;

            bool fromXElement( std::ostream& message, xml::XElement& xelement );
        };
    }
}
